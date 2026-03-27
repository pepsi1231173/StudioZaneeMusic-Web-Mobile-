using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using DuAnBai3.Data;
using DuAnBai3.Hubs;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using DuAnBai3.Models;

namespace DuAnBai3.BackgroundServices
{
    public class BookingCleanupService : BackgroundService
    {
        private readonly IServiceProvider _sp;
        private readonly IHubContext<BookingHub> _hub;

        public BookingCleanupService(IServiceProvider sp, IHubContext<BookingHub> hub)
        {
            _sp = sp;
            _hub = hub;
        }

        protected override async Task ExecuteAsync(CancellationToken ct)
        {
            try
            {
                while (!ct.IsCancellationRequested)
                {
                    using var scope = _sp.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                    var now = DateTime.Now;

                    // Lấy các booking có trạng thái booked hoặc active
                    var dueBookings = await db.Bookings
                        .Where(b => b.Status == "booked" || b.Status == "active")
                        .ToListAsync(ct);

                    // Lọc những booking đã hết giờ thuê
                    var toComplete = dueBookings
                        .Where(b => b.RentalDate.Date.Add(b.StartTime).AddHours(b.RentalDuration) < now)
                        .ToList();

                    foreach (var b in toComplete)
                    {
                        b.Status = "completed"; // đổi trạng thái sang completed
                        b.UpdatedAt = now;
                    }

                    if (toComplete.Any())
                    {
                        await db.SaveChangesAsync(ct);

                        // Phát event SignalR cho client cập nhật trạng thái realtime
                        foreach (var b in toComplete)
                        {
                            await _hub.Clients.All.SendAsync("BookingStatusChanged",
                                b.Id,
                                b.RoomId,
                                b.RentalDate,
                                b.StartTime.Hours,
                                b.RentalDuration,
                                b.Status,
                                cancellationToken: ct);
                        }
                    }

                    await Task.Delay(TimeSpan.FromMinutes(30), ct);
                }
            }
            catch (TaskCanceledException)
            {
                // Bình thường khi app dừng, bỏ qua
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[BookingCleanupService] Exception: {ex.Message}");
            }
        }
    }
}
