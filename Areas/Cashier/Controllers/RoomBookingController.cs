using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using DuAnBai3.Hubs;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace DuAnBai3.Areas.Cashier.Controllers
{
    [Area("Cashier")]
    [Authorize(Roles = "cashier")]
    [AutoValidateAntiforgeryToken]
    public class RoomBookingController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<BookingHub> _hub;

        public RoomBookingController(ApplicationDbContext context, IHubContext<BookingHub> hub)
        {
            _context = context;
            _hub = hub;
        }

        public IActionResult Index()
        {
            var bookings = _context.Bookings
                .OrderBy(b => b.RentalDate)
                .ThenBy(b => b.StartTime)
                .ToList();

            return View(bookings);
        }

        [HttpPost]
        public async Task<IActionResult> PayByCash(int bookingId)
        {
            var booking = await _context.Bookings.FindAsync(bookingId);
            if (booking == null) return NotFound();

            booking.Status = "paid_cash";
            await _context.SaveChangesAsync();

            // Gửi sự kiện cập nhật nếu bạn dùng SignalR để đồng bộ giao diện realtime
            await _hub.Clients.All.SendAsync("BookingStatusUpdated", bookingId, booking.Status);

            TempData["SuccessMessage"] = $"Thanh toán tiền mặt cho đơn #{booking.DailyBookingNumber:D4} thành công.";
            return RedirectToAction("Index");
        }

        [HttpPost]
        public async Task<IActionResult> PayByBankTransfer(int bookingId)
        {
            var booking = await _context.Bookings.FindAsync(bookingId);
            if (booking == null) return NotFound();

            booking.Status = "paid_bank";
            await _context.SaveChangesAsync();

            // Gửi sự kiện cập nhật nếu bạn dùng SignalR để đồng bộ giao diện realtime
            await _hub.Clients.All.SendAsync("BookingStatusUpdated", bookingId, booking.Status);

            TempData["SuccessMessage"] = $"Thanh toán chuyển khoản cho đơn #{booking.DailyBookingNumber:D4} thành công.";
            return RedirectToAction("Index");
        }
    }
     public class DailyBookingDto
    {
        public DateTime RentalDate { get; set; }
        public int DailyNumber { get; set; }
    }
}
