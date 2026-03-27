using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using DuAnBai3.Data;
using DuAnBai3.Hubs;
using DuAnBai3.Models;

public class BookingMonitorService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IHubContext<BookingHub> _hubContext;

    public BookingMonitorService(IServiceScopeFactory scopeFactory, IHubContext<BookingHub> hubContext)
    {
        _scopeFactory = scopeFactory;
        _hubContext = hubContext;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var now = DateTime.Now;
            var today = now.Date;
            var nowTime = new TimeSpan(now.Hour, now.Minute, 0);

            // Trường hợp 1: Pending đến đúng giờ bắt đầu thì hủy luôn
            var pendingBookingsToday = await db.Bookings
                .Where(b => b.Status == "pending" && b.RentalDate == today)
                .ToListAsync(stoppingToken);

            var shouldCancel = pendingBookingsToday
                .Where(b => nowTime >= b.StartTime) // Đến hoặc sau giờ bắt đầu
                .ToList();

            foreach (var booking in shouldCancel)
            {
                booking.Status = "cancelled";
                booking.UpdatedAt = now;

                await _hubContext.Clients.All.SendAsync("BookingStatusChanged",
                    booking.Id,
                    booking.RoomId,
                    booking.RentalDate.ToString("yyyy-MM-dd"),
                    booking.StartTime.ToString(@"hh\:mm"),
                    booking.RentalDuration,
                    "cancelled", // ✅ CHUẨN status
                    cancellationToken: stoppingToken);
            }


            // Trường hợp 2: Active đến hết giờ thì hoàn tất
            var activeBookingsToday = await db.Bookings
                .Where(b => b.Status == "active" && b.RentalDate == today)
                .ToListAsync(stoppingToken);

            var finishedActive = activeBookingsToday
                .Where(b => nowTime >= b.StartTime + TimeSpan.FromHours(b.RentalDuration))
                .ToList();

            foreach (var booking in finishedActive)
            {
                booking.Status = "completed";
                booking.UpdatedAt = now;

                await _hubContext.Clients.All.SendAsync("BookingStatusChanged",
                    booking.Id,
                    booking.RoomId,
                    booking.RentalDate.ToString("yyyy-MM-dd"),
                    booking.StartTime.ToString(@"hh\:mm"),
                    booking.RentalDuration,
                    "completed",
                    cancellationToken: stoppingToken);
            }

            await db.SaveChangesAsync(stoppingToken);

            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
        }
    }


}
