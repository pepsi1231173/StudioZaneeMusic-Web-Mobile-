using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using System;
using System.Linq;

namespace DuAnBai3.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecordingApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public RecordingApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ GET: api/RecordingApi
        [HttpGet]
        public IActionResult GetAll()
        {
            var bookings = _context.RecordingBookings
                .OrderByDescending(b => b.CreatedAt)
                .ToList();

            return Ok(bookings);
        }

        // ✅ GET: api/RecordingApi/{id}
        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            var booking = _context.RecordingBookings.FirstOrDefault(b => b.Id == id);
            if (booking == null)
                return NotFound(new { message = "Không tìm thấy đơn thu âm." });

            return Ok(booking);
        }

        // ✅ POST: api/RecordingApi
        // → Flutter gửi dữ liệu form lên đây
        [HttpPost]
        public IActionResult Create([FromBody] RecordingBooking booking)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // 🔹 Tự động tính giá theo gói dịch vụ
            // 🔹 Tự động tính giá theo gói dịch vụ (linh hoạt)
            int price = 0;
            if (booking.RecordingPackage.Contains("thô", StringComparison.OrdinalIgnoreCase))
                price = 200_000;
            else if (booking.RecordingPackage.Contains("chỉnh sửa", StringComparison.OrdinalIgnoreCase)
                     && !booking.RecordingPackage.Contains("Full", StringComparison.OrdinalIgnoreCase))
                price = 400_000;
            else if (booking.RecordingPackage.Contains("Full", StringComparison.OrdinalIgnoreCase))
                price = 900_000 * booking.Duration;

            booking.Price = price;
            booking.CreatedAt = DateTime.Now;
            booking.Status = "pending";


            booking.Price = price;
            booking.Status = "pending"; // Mặc định trạng thái chờ xác nhận
            booking.CreatedAt = DateTime.Now;

            _context.RecordingBookings.Add(booking);
            _context.SaveChanges();

            // ✅ Trả về kết quả để Flutter chuyển hướng qua hóa đơn
            return Ok(new
            {
                success = true,
                message = "Đặt lịch thu âm thành công!",
                bookingId = booking.Id
            });
        }

        // ✅ PUT: api/RecordingApi/{id}
        // → Cập nhật trạng thái (admin hoặc xác nhận)
        [HttpPut("{id}")]
        public IActionResult Update(int id, [FromBody] RecordingBooking updated)
        {
            var booking = _context.RecordingBookings.FirstOrDefault(b => b.Id == id);
            if (booking == null)
                return NotFound(new { message = "Không tìm thấy đơn thu âm." });

            booking.Status = updated.Status;
            _context.SaveChanges();

            return Ok(new
            {
                success = true,
                message = "Đặt lịch thu âm thành công!",
                bookingId = booking.Id,
                booking = booking
            });

        }
        // ✅ DELETE: api/RecordingApi/{id}
        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var booking = _context.RecordingBookings.FirstOrDefault(b => b.Id == id);
            if (booking == null)
                return NotFound(new { message = "Không tìm thấy đơn thu âm." });

            _context.RecordingBookings.Remove(booking);
            _context.SaveChanges();

            return Ok(new { success = true, message = "Xóa đơn thu âm thành công!" });
        }
    }
}
