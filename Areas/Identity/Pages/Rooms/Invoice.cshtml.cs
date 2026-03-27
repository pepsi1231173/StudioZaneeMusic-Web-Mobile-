using System;
using System.Linq;
using DuAnBai3.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace DuAnBai3.Areas.Identity.Pages.Rooms
{
    public class InvoiceModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public InvoiceModel(ApplicationDbContext context)
        {
            _context = context;
        }

        [BindProperty(SupportsGet = true)]
        public int BookingId { get; set; }

        public Booking Booking { get; set; } = null!;
        public int NormalHours { get; set; }
        public int DiscountHours { get; set; }
        public int ExtraGuests { get; set; }
        public int ExtraFee { get; set; }
        public decimal FinalPrice { get; set; }
        public decimal PricePerHour { get; set; }
        public decimal DiscountPrice { get; set; }
        public int ExtraGuestFee { get; set; } = 30000;

        public IActionResult OnGet()
        {
            Booking = _context.Bookings.FirstOrDefault(b => b.Id == BookingId);
            if (Booking == null)
                return Content("❌ Không tìm thấy thông tin đặt phòng!");

            string room = (Booking.RoomId ?? "").Trim().ToUpper();

            if (string.IsNullOrEmpty(room))
                return Content("❌ Không xác định được phòng cho đơn này. RoomId đang bị null!");

            bool isWeekend = Booking.RentalDate.DayOfWeek == DayOfWeek.Saturday || Booking.RentalDate.DayOfWeek == DayOfWeek.Sunday;
            int startHour = Booking.StartTime.Hours;
            int duration = Booking.RentalDuration;

            int maxGuests = room switch
            {
                "B" => 20,
                "C" => 30,
                _ => 10
            };

            ExtraGuests = Math.Max(0, Booking.GuestCount - maxGuests);
            ExtraFee = ExtraGuests * ExtraGuestFee;

            bool IsGoldenHour(int h) => h >= 14 && h < 17;

            NormalHours = 0;
            DiscountHours = 0;

            for (int i = 0; i < duration; i++)
            {
                int h = startHour + i;
                if (IsGoldenHour(h))
                    DiscountHours++;
                else
                    NormalHours++;
            }

            PricePerHour = room switch
            {
                "B" => isWeekend ? 400000 : 360000,
                "C" => isWeekend ? 600000 : 540000,
                _ => isWeekend ? 200000 : 180000,
            };

            DiscountPrice = room switch
            {
                "B" => 240000,
                "C" => 360000,
                _ => 120000,
            };

            FinalPrice = NormalHours * PricePerHour + DiscountHours * DiscountPrice + ExtraFee;

            // Cập nhật lại giá nếu cần
            Booking.Price = (int)FinalPrice;
            _context.SaveChanges();

            return Page();
        }
    }
}
