using DuAnBai3.Models;
using Microsoft.AspNetCore.Mvc;

namespace DuAnBai3.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class RecordingBookingController : Controller
    {
        private readonly ApplicationDbContext _context;
        public RecordingBookingController(ApplicationDbContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            var bookings = _context.RecordingBookings
                .OrderByDescending(r => r.RecordingDate)
                .ThenBy(r => r.RecordingTime)
                .ToList();
            return View(bookings);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Confirm(int id)
        {
            var booking = _context.RecordingBookings.Find(id);
            if (booking != null && booking.Status?.ToLower() == "pending")
            {
                booking.Status = "confirmed";
                _context.SaveChanges();
            }
            return RedirectToAction("Index");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Cancel(int id)
        {
            var booking = _context.RecordingBookings.Find(id);
            if (booking != null && booking.Status?.ToLower() != "canceled")
            {
                booking.Status = "canceled";
                _context.SaveChanges();
            }
            return RedirectToAction("Index");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Delete(int id)
        {
            var booking = _context.RecordingBookings.Find(id);
            if (booking != null)
            {
                _context.RecordingBookings.Remove(booking);
                _context.SaveChanges();
            }
            return RedirectToAction("Index");
        }
    }
}
