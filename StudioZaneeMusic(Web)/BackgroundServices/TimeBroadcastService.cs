using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Hosting;
using System;
using System.Threading;
using System.Threading.Tasks;
using DuAnBai3.Hubs;

public class TimeBroadcastService : BackgroundService
{
    private readonly IHubContext<BookingHub> _hubContext;

    public TimeBroadcastService(IHubContext<BookingHub> hubContext)
    {
        _hubContext = hubContext;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                var now = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss"); // 24h format
                await _hubContext.Clients.All.SendAsync("ReceiveTime", now, cancellationToken: stoppingToken);
                await Task.Delay(1000, stoppingToken); // 1 giây gửi 1 lần
            }
        }
        catch (TaskCanceledException)
        {
            // Bình thường khi app dừng, bỏ qua
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[TimeBroadcastService] Exception: {ex.Message}");
        }
    }

}
