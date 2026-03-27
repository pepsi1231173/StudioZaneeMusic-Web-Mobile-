using DuAnBai3.Data;
using DuAnBai3.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System;
using System.Linq;

namespace DuAnBai3.Areas.Identity.Pages.Recording
{
    public class RecordingModel : PageModel
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public RecordingModel(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        public class InputModel
        {
            [BindProperty] public string RecordingPackage { get; set; }
            [BindProperty] public DateTime RecordingDate { get; set; }
            [BindProperty] public int RecordingStartHour { get; set; }
            [BindProperty] public int RecordingDuration { get; set; } = 1;
            [BindProperty] public string CustomerName { get; set; }
            [BindProperty] public string CustomerEmail { get; set; }
            [BindProperty] public string CustomerPhone { get; set; }
        }

        [BindProperty]
        public InputModel Input { get; set; } = new InputModel();

        // Kiểm tra trùng giờ
        private bool IsDuplicateBooking(DateTime date, int startHour, int duration)
        {
            var bookings = _context.RecordingBookings
                .Where(b => b.RecordingDate.Date == date.Date && b.Status != "cancelled");

            foreach (var b in bookings)
            {
                var bStart = b.RecordingTime.Hours;
                var bEnd = bStart + b.Duration;
                var newStart = startHour;
                var newEnd = startHour + duration;

                if (newStart < bEnd && bStart < newEnd) return true;
            }
            return false;
        }
        public async Task<IActionResult> OnGetAsync()
        {
            if (User.Identity.IsAuthenticated)
            {
                var user = await _userManager.GetUserAsync(User);
                if (user != null)
                {
                    Input.CustomerName = user.FullName; // hoặc user.UserName nếu không có FullName
                    Input.CustomerEmail = user.Email;
                    Input.CustomerPhone = user.PhoneNumber;
                }
            }

            // Mặc định chọn ngày hôm nay
            Input.RecordingDate = DateTime.Today;

            return Page();
        }
        public IActionResult OnPost()
        {
            if (!ModelState.IsValid) return Page();

            if (IsDuplicateBooking(Input.RecordingDate, Input.RecordingStartHour, Input.RecordingDuration))
            {
                ModelState.AddModelError("", "❌ Dịch vụ thu âm vào khung giờ này đã được đặt. Vui lòng chọn giờ khác.");
                return Page();
            }

            int price = Input.RecordingPackage switch
            {
                "Thu âm thô" => 200000,
                "Thu âm chỉnh sửa" => 400000,
                "Full chỉnh sửa & tư vấn kỹ thuật" => 900000,
                _ => 0
            };

            var booking = new RecordingBooking
            {
                CustomerName = Input.CustomerName,
                CustomerEmail = Input.CustomerEmail,
                CustomerPhone = Input.CustomerPhone,
                RecordingPackage = Input.RecordingPackage,
                Price = price,
                RecordingDate = Input.RecordingDate,
                RecordingTime = new TimeSpan(Input.RecordingStartHour, 0, 0),
                Duration = Input.RecordingDuration,
                CreatedAt = DateTime.Now,
                Status = "pending"
            };

            _context.RecordingBookings.Add(booking);
            _context.SaveChanges();

            return Redirect($"/Identity/Recording/InvoiceRecording/{booking.Id}");
        }
    }
}
