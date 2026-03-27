using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using DuAnBai3.Data;
using System;
using System.Globalization;
using System.Linq;

namespace DuAnBai3.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class InvoiceApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public InvoiceApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        public class BookingInputModel
        {
            public string CustomerName { get; set; }
            public string CustomerPhone { get; set; }
            public string CustomerEmail { get; set; }
            public DateTime RentalDate { get; set; }
            public string StartTime { get; set; }   // "08:00:00"
            public int RentalDuration { get; set; }
            public int GuestCount { get; set; }
            public string RoomId { get; set; }
        }

        [HttpPost("Create")]
        public IActionResult CreateBooking([FromBody] BookingInputModel model)
        {
            if (model == null)
                return BadRequest(new { message = "Dữ liệu không hợp lệ." });

            try
            {
                if (!TimeSpan.TryParseExact(model.StartTime, @"hh\:mm\:ss", CultureInfo.InvariantCulture, out var startTime))
                    return BadRequest(new { message = $"Giờ bắt đầu không hợp lệ: {model.StartTime}" });

                var endTime = startTime.Add(TimeSpan.FromHours(model.RentalDuration));
                int countToday = _context.Bookings.Count(b => b.RentalDate.Date == model.RentalDate.Date);

                var booking = new Booking
                {
                    CustomerName = model.CustomerName,
                    CustomerPhone = model.CustomerPhone,
                    CustomerEmail = model.CustomerEmail,
                    RentalDate = model.RentalDate,
                    StartTime = startTime,
                    EndTime = endTime,
                    RentalDuration = model.RentalDuration,
                    GuestCount = model.GuestCount,
                    RoomId = model.RoomId,
                    Status = "pending",
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now,
                    DailyBookingNumber = countToday + 1
                };

                // 💰 Tính tổng và chi tiết
                var (totalPrice, details) = TinhTongTienVaChiTiet(booking);
                booking.Price = totalPrice;

                _context.Bookings.Add(booking);
                _context.SaveChanges();

                var invoice = TaoHoaDon(booking, totalPrice, details);

                return Ok(new
                {
                    message = "✅ Đặt phòng thành công!",
                    bookingId = booking.Id,
                    invoice
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine("💥 Lỗi server khi đặt phòng: " + ex);
                return StatusCode(500, new
                {
                    message = "❌ Lỗi khi lưu đơn đặt phòng.",
                    error = ex.InnerException?.Message ?? ex.Message
                });
            }
        }

        // 🔹 Trả về tổng tiền & chi tiết từng phần
        private (int total, dynamic details) TinhTongTienVaChiTiet(Booking booking)
        {
            var culture = new CultureInfo("vi-VN");
            string room = (booking.RoomId ?? "A").Trim().ToUpper();

            bool isWeekend = booking.RentalDate.DayOfWeek == DayOfWeek.Saturday ||
                             booking.RentalDate.DayOfWeek == DayOfWeek.Sunday;

            int startHour = booking.StartTime.Hours;
            int duration = booking.RentalDuration;

            int maxGuests = room switch
            {
                "B" => 20,
                "C" => 30,
                _ => 10
            };

            int extraGuests = Math.Max(0, booking.GuestCount - maxGuests);
            int extraFee = extraGuests * 30_000;

            bool IsGoldenHour(int h) => h >= 14 && h < 17;
            int normalHours = 0, discountHours = 0;

            for (int i = 0; i < duration; i++)
            {
                int h = startHour + i;
                if (IsGoldenHour(h))
                    discountHours++;
                else
                    normalHours++;
            }

            int pricePerHour = room switch
            {
                "B" => isWeekend ? 400_000 : 360_000,
                "C" => isWeekend ? 600_000 : 540_000,
                _ => isWeekend ? 200_000 : 180_000,
            };

            int discountPrice = room switch
            {
                "B" => 240_000,
                "C" => 360_000,
                _ => 120_000,
            };

            int total = (normalHours * pricePerHour) + (discountHours * discountPrice) + extraFee;

            // 🔹 Trả về dữ liệu định dạng sẵn
            var details = new
            {
                GioThuong = $"{normalHours} giờ x {pricePerHour.ToString("N0", culture)} VNĐ = {(normalHours * pricePerHour).ToString("N0", culture)} VNĐ",
                GioKhuyenMai = $"{discountHours} giờ x {discountPrice.ToString("N0", culture)} VNĐ = {(discountHours * discountPrice).ToString("N0", culture)} VNĐ",
                PhuThuKhach = $"{extraGuests} khách x 30.000 VNĐ = {extraFee.ToString("N0", culture)} VNĐ"
            };

            return (total, details);
        }

        // 🔹 Hóa đơn trả về Flutter (định dạng đẹp)
        private object TaoHoaDon(Booking booking, int total, dynamic details)
        {
            var culture = new CultureInfo("vi-VN");

            return new
            {
                MaDon = $"#{booking.DailyBookingNumber:D4}",
                TenKhachHang = booking.CustomerName,
                SoDienThoai = booking.CustomerPhone,
                Email = booking.CustomerEmail,
                NgayThue = booking.RentalDate.ToString("dd/MM/yyyy"),
                GioBatDau = booking.StartTime.ToString(@"hh\:mm"),
                ThoiGianThue = $"{booking.RentalDuration} giờ",
                SoKhach = booking.GuestCount,
                Phong = booking.RoomId,
                GiaChiTiet = details,
                TongTien = $"{total.ToString("N0", culture)} VNĐ"
            };
        }
        [HttpGet("{id}")]
        public IActionResult GetInvoice(int id)
        {
            var booking = _context.Bookings.FirstOrDefault(b => b.Id == id);
            if (booking == null)
                return NotFound(new { message = "Không tìm thấy đơn đặt phòng." });

            var (total, details) = TinhTongTienVaChiTiet(booking);
            var invoice = TaoHoaDon(booking, total, details);

            return Ok(invoice);
        }

    }
}
