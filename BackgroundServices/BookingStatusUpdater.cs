using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using DuAnBai3.Models;
using DuAnBai3.Hubs;
using DuAnBai3.Services;

namespace DuAnBai3.Services
{
    /// <summary>
    /// Job nền: 15s quét một lần
    /// • booked   → active      (đến giờ bắt đầu)
    /// • active   → completed   (hết giờ thuê)
    /// • pending  → cancelled   (quá giờ kết thúc mà vẫn chưa duyệt)
    /// Đồng thời broadcast danh sách phòng đang bảo trì.
    /// </summary>
    public class BookingStatusUpdater : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IHubContext<BookingHub> _hub;
        private readonly TimeSpan _interval = TimeSpan.FromSeconds(15);

        public BookingStatusUpdater(IServiceScopeFactory scopeFactory, IHubContext<BookingHub> hub)
        {
            _scopeFactory = scopeFactory;
            _hub = hub;
        }

        protected override async Task ExecuteAsync(CancellationToken ct)
        {
            try
            {
                while (!ct.IsCancellationRequested)
                {
                    using var scope = _scopeFactory.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                    var maintenanceService = scope.ServiceProvider.GetRequiredService<MaintenanceService>();

                    var now = DateTime.Now;
                    var today = now.Date;
                    var nowTime = now.TimeOfDay;

                    /* booked → active */
                    var toActive = await db.Bookings
                        .Where(b => b.Status == "booked" &&
                                    (b.RentalDate < today ||
                                     (b.RentalDate == today && b.StartTime <= nowTime)))
                        .ToListAsync(ct);

                    foreach (var b in toActive)
                    {
                        b.Status = "active";
                        b.UpdatedAt = now;
                    }
                    await db.SaveChangesAsync(ct);

                    foreach (var b in toActive)
                    {
                        await _hub.Clients.All.SendAsync("BookingStatusChanged",
                            b.Id, b.RoomId, b.RentalDate,
                            b.StartTime.ToString(@"hh\:mm"), b.RentalDuration,
                            "active", cancellationToken: ct);
                    }

                    /* active → completed */
                    var toCompleted = await db.Bookings
                        .Where(b => b.Status == "active" &&
                                    (b.RentalDate < today ||
                                     (b.RentalDate == today &&
                                      b.StartTime.Add(TimeSpan.FromHours(b.RentalDuration)) <= nowTime)))
                        .ToListAsync(ct);

                    foreach (var b in toCompleted)
                    {
                        b.Status = "completed";
                        b.UpdatedAt = now;
                    }
                    await db.SaveChangesAsync(ct);

                    foreach (var b in toCompleted)
                    {
                        await _hub.Clients.All.SendAsync("BookingStatusChanged",
                            b.Id, b.RoomId, b.RentalDate,
                            b.StartTime.ToString(@"hh\:mm"), b.RentalDuration,
                            "completed", cancellationToken: ct);
                    }

                    /* pending → cancelled */
                    var toCancel = await db.Bookings
                        .Where(b => b.Status == "pending" &&
                                    (b.RentalDate < today ||
                                     (b.RentalDate == today &&
                                      b.StartTime.Add(TimeSpan.FromHours(b.RentalDuration)) <= nowTime)))
                        .ToListAsync(ct);

                    foreach (var b in toCancel)
                    {
                        b.Status = "cancelled";
                        b.UpdatedAt = now;
                    }
                    await db.SaveChangesAsync(ct);

                    foreach (var b in toCancel)
                    {
                        await _hub.Clients.All.SendAsync("BookingStatusChanged",
                            b.Id, b.RoomId, b.RentalDate,
                            b.StartTime.ToString(@"hh\:mm"), b.RentalDuration,
                            "cancelled", cancellationToken: ct);
                    }

                    /* broadcast danh sách phòng bảo trì */
                    var maintenanceRooms = maintenanceService.GetMaintenanceRooms();
                    await _hub.Clients.All.SendAsync("MaintenanceUpdated", maintenanceRooms, cancellationToken: ct);

                    await Task.Delay(_interval, ct);
                }
            }
            catch (TaskCanceledException)
            {
                // Cancel bình thường, không log lỗi
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[BookingStatusUpdater] Exception: {ex.Message}");
            }
        }
    }
}
