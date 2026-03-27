using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using DuAnBai3.Hubs;
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using DuAnBai3.Models;

namespace DuAnBai3.Services
{
    public class BookingStatusService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly IHubContext<BookingHub> _hub;

        public BookingStatusService(IServiceProvider serviceProvider, IHubContext<BookingHub> hub)
        {
            _serviceProvider = serviceProvider;
            _hub = hub;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                using var scope = _serviceProvider.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                var now = DateTime.Now;

                var activeBookings = await db.Bookings
                    .Where(b => b.Status == "active")
                    .ToListAsync(stoppingToken);

                foreach (var booking in activeBookings)
                {
                    var endTime = booking.RentalDate.Date + booking.StartTime + TimeSpan.FromHours(booking.RentalDuration);
                    if (now >= endTime)
                    {
                        booking.Status = "completed";
                        booking.UpdatedAt = now;

                        // Gửi SignalR để UI cập nhật
                        await _hub.Clients.All.SendAsync("BookingStatusChanged",
                            booking.Id,
                            booking.RoomId,
                            booking.RentalDate.ToString("yyyy-MM-dd"),
                            booking.StartTime.Hours,
                            booking.RentalDuration,
                            booking.Status
                        );
                    }
                }

                await db.SaveChangesAsync(stoppingToken);

                // Lặp lại sau mỗi phút
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
    }
}
