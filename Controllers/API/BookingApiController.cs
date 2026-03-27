using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using System;
using System.Linq;

namespace DuAnBai3.Controllers.Api
{
    [ApiController]
    [Route("api/[controller]")]
    public class BookingApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public BookingApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ Lấy toàn bộ booking
        [HttpGet]
        public IActionResult GetBookings()
        {
            var bookings = _context.Bookings.ToList();
            return Ok(bookings);
        }

        // ✅ Lấy chi tiết booking theo Id
        [HttpGet("{id}")]
        public IActionResult GetBooking(int id)
        {
            var booking = _context.Bookings.FirstOrDefault(b => b.Id == id);
            if (booking == null)
                return NotFound();

            return Ok(booking);
        }

        // ✅ Lấy lịch 7 ngày của một phòng (an toàn với NULL)
        [HttpGet("room/{roomId}")]
        public IActionResult GetRoomSchedule([FromRoute] string roomId)
        {
            var bookings = _context.Bookings
                .Where(b => b.RoomId == roomId)
                .ToList();

            var result = bookings.Select(b =>
            {
                // safe getters: có thể DB chứa NULL -> xử lý dự phòng
                DateTime? rentalDate = null;
                try
                {
                    // nếu kiểu trong model là DateTime? sẽ OK, nếu không thì vẫn thử
                    rentalDate = b.RentalDate == default(DateTime) ? (DateTime?)null : b.RentalDate;
                }
                catch
                {
                    rentalDate = null;
                }

                TimeSpan? startTime = null;
                TimeSpan? endTime = null;
                int rentalDuration = b.RentalDuration;

                try { startTime = b.StartTime; } catch { startTime = null; }
                try { endTime = b.EndTime; } catch { endTime = null; }

                string status = "unknown";
                try { status = string.IsNullOrWhiteSpace(b.Status) ? "unknown" : b.Status.ToLower(); } catch { status = "unknown"; }

                int startHour = startTime.HasValue ? startTime.Value.Hours : -1;
                int endHour;

                if (endTime.HasValue)
                {
                    endHour = endTime.Value.Hours;
                }
                else if (startTime.HasValue)
                {
                    endHour = (startTime.Value + TimeSpan.FromHours(rentalDuration)).Hours;
                }
                else
                {
                    endHour = -1;
                }

                return new
                {
                    b.Id,
                    b.RoomId,
                    RoomName = b.RoomId switch
                    {
                        "A" => "Phòng A",
                        "B" => "Phòng B",
                        "C" => "Phòng C",
                        _ => "Không xác định"
                    },
                    RentalDate = rentalDate.HasValue ? rentalDate.Value.ToString("yyyy-MM-dd") : null,
                    StartHour = startHour,
                    EndHour = endHour,
                    RentalDuration = rentalDuration,
                    Status = status
                };
            }).ToList();

            return Ok(result);
        }

        // ✅ API tạo booking mới (có validation tránh null và kiểm tra trùng giờ an toàn)
        [HttpPost("create")]
        public IActionResult CreateBooking([FromBody] Booking model)
        {
            if (model == null)
                return BadRequest(new { message = "Dữ liệu không hợp lệ" });

            // Bắt buộc: RentalDate & StartTime & RentalDuration phải có giá trị hợp lệ
            // Nếu model.RentalDate là DateTime (non-nullable) thì đảm bảo không phải default
            if (model.RentalDate == default(DateTime))
                return BadRequest(new { message = "Vui lòng cung cấp RentalDate hợp lệ." });

            // Nếu StartTime có thể null trong DB/model, kiểm tra ở đây
            if (model.StartTime == default(TimeSpan))
                return BadRequest(new { message = "Vui lòng cung cấp StartTime hợp lệ." });

            if (model.RentalDuration <= 0)
                return BadRequest(new { message = "RentalDuration phải lớn hơn 0." });

            // 🕐 Tính EndTime ngay từ đầu (lưu vào model.EndTime)
            var endTime = model.StartTime + TimeSpan.FromHours(model.RentalDuration);

            // 🧮 Tính giá theo từng loại phòng
            int basePricePerHour = model.RoomId switch
            {
                "A" => 200_000,
                "B" => 150_000,
                "C" => 100_000,
                _ => 120_000
            };

            int maxGuests = model.RoomId == "A" ? 8 :
                            model.RoomId == "B" ? 6 : 4;

            int extraFee = model.GuestCount > maxGuests
                ? (model.GuestCount - maxGuests) * 30_000
                : 0;

            model.Price = basePricePerHour * model.RentalDuration + extraFee;
            model.Status = "pending";
            model.CreatedAt = DateTime.Now;
            model.UpdatedAt = DateTime.Now;
            model.EndTime = endTime; // ✅ Gán luôn để lưu DB

            // ❌ Không cho đặt ngày quá khứ
            if (model.RentalDate.Date < DateTime.Now.Date)
                return BadRequest(new { message = "❌ Không thể đặt phòng cho ngày đã qua." });

            // ❌ Không cho đặt ngoài giờ (8h–22h)
            if (model.StartTime.Hours < 8 || endTime.Hours > 22)
                return BadRequest(new { message = "❌ Giờ đặt phải nằm trong khung 08:00 - 22:00." });

            // ========================
            // ✅ Kiểm tra trùng giờ (an toàn khi DB có NULL)
            // Chỉ so sánh với những booking có StartTime không null và EndTime không null (hoặc có thể suy ra EndTime)
            // ========================
            bool isOverlap = _context.Bookings.Any(b =>
                b.RoomId == model.RoomId &&
                // kiểm tra RentalDate tồn tại và cùng ngày
                b.RentalDate != default(DateTime) &&
                b.RentalDate.Date == model.RentalDate.Date &&
                // trạng thái còn hiệu lực
                (b.Status == "pending" || b.Status == "active") &&
                // và cả b.StartTime phải có giá trị hợp lệ (nếu DB có null, dòng đó sẽ bị bỏ qua)
                b.StartTime != default(TimeSpan) &&
                (
                    // lấy bEnd = nếu EndTime != null thì b.EndTime else b.StartTime + duration
                    (
                        // case A: model.StartTime trong khoảng [b.StartTime, bEnd)
                        model.StartTime >= b.StartTime &&
                        model.StartTime < (b.EndTime != null ? b.EndTime : b.StartTime + TimeSpan.FromHours(b.RentalDuration))
                    ) ||
                    (
                        // case B: endTime trong (b.StartTime, bEnd]
                        endTime > b.StartTime &&
                        endTime <= (b.EndTime != null ? b.EndTime : b.StartTime + TimeSpan.FromHours(b.RentalDuration))
                    ) ||
                    (
                        // case C: model bao phủ toàn bộ b
                        model.StartTime <= b.StartTime &&
                        endTime >= (b.EndTime != null ? b.EndTime : b.StartTime + TimeSpan.FromHours(b.RentalDuration))
                    )
                )
            );

            if (isOverlap)
            {
                return BadRequest(new { message = "❌ Khung giờ này đã có người đặt. Vui lòng chọn giờ khác." });
            }

            // ✅ Lưu vào DB
            _context.Bookings.Add(model);
            _context.SaveChanges();

            return Ok(new
            {
                message = "✅ Đặt phòng thành công!",
                totalPrice = model.Price,
                formattedPrice = model.Price.ToString("N0", new System.Globalization.CultureInfo("vi-VN")) + " ₫"
            });
        }
    }
}
