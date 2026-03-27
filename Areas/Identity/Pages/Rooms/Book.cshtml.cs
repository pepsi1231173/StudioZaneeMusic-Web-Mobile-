using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using DuAnBai3.Hubs;
using DuAnBai3.Models;
using System;
using System.ComponentModel.DataAnnotations;
using System.Threading.Tasks;

namespace DuAnBai3.Areas.Identity.Pages.Rooms
{
    public class BookModel : PageModel
    {
        private readonly IConfiguration _configuration;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IHubContext<BookingHub> _hubContext;

        public BookModel(UserManager<ApplicationUser> userManager, IConfiguration configuration, IHubContext<BookingHub> hubContext)
        {
            _userManager = userManager;
            _configuration = configuration;
            _hubContext = hubContext;
        }

        [BindProperty]
        public BookingInputModel Booking { get; set; } = new BookingInputModel();

        [BindProperty(SupportsGet = true)]
        public string? Room { get; set; }

        [TempData]
        public string SuccessMessage { get; set; } = string.Empty;

        private string ConnectionString => _configuration.GetConnectionString("DefaultConnection") ?? throw new Exception("Connection string not found");

        public async Task OnGetAsync()
        {
            Booking.RentalDate = DateTime.Today;

            if (User.Identity.IsAuthenticated)
            {
                var user = await _userManager.GetUserAsync(User);
                Booking.CustomerName = user.FullName ?? user.UserName;
                Booking.CustomerEmail = user.Email;
                Booking.CustomerPhone = user.PhoneNumber;
            }

            if (!string.IsNullOrEmpty(Room))
            {
                Booking.RoomId = Room;
            }
        }

        public async Task<IActionResult> OnPostAsync()
        {
            Booking.StartTime = TimeSpan.FromHours(Booking.StartHour);

            if (Booking.RentalDate.Date < DateTime.Today)
            {
                ModelState.AddModelError("Booking.RentalDate", "Ngày thuê phải từ hôm nay trở đi.");
            }

            if (!ModelState.IsValid)
                return Page();

            if (Booking.StartHour < 8 || Booking.StartHour > 22)
            {
                ModelState.AddModelError("Booking.StartHour", "Giờ bắt đầu phải từ 08 đến 22.");
                return Page();
            }

            var endHour = Booking.StartHour + Booking.RentalDuration;
            if (endHour > 22)
            {
                ModelState.AddModelError("Booking.RentalDuration", "Thời gian thuê vượt quá 22 giờ.");
                return Page();
            }

            var now = DateTime.Now;
            if (Booking.RentalDate.Date == now.Date && Booking.StartHour <= now.Hour)
            {
                ModelState.AddModelError("Booking.StartHour", "Giờ đã qua, vui lòng chọn giờ khác.");
                return Page();
            }

            if (await IsOverlappingBookingAsync(Booking))
            {
                ModelState.AddModelError(string.Empty, "Giờ thuê đã bị trùng, vui lòng chọn khung giờ khác.");
                return Page();
            }

            int price = CalculatePrice(Booking);
            int dailyBookingNumber = GetNextDailyBookingNumber(Booking.RentalDate);

            int bookingId = SaveBooking(Booking, price, dailyBookingNumber);
            if (bookingId == 0)
            {
                ModelState.AddModelError(string.Empty, "❌ Lỗi khi lưu dữ liệu đặt phòng.");
                return Page();
            }

            var newBooking = new Booking
            {
                Id = bookingId,
                CustomerName = Booking.CustomerName,
                CustomerPhone = Booking.CustomerPhone,
                CustomerEmail = Booking.CustomerEmail,
                RentalDate = Booking.RentalDate,
                StartTime = Booking.StartTime,
                RentalDuration = Booking.RentalDuration,
                RoomId = Booking.RoomId,
                GuestCount = Booking.GuestCount,
                Status = "pending",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
                Price = price,
                DailyBookingNumber = dailyBookingNumber
            };

            // ✅ Gửi object JSON chuẩn để trang Admin render thẻ đơn mới
            await _hubContext.Clients.All.SendAsync("BookingCreated", new
            {
                id = newBooking.Id,
                roomId = newBooking.RoomId,
                rentalDate = newBooking.RentalDate.ToString("yyyy-MM-dd"),
                startTime = newBooking.StartTime.ToString(@"hh\:mm"),
                rentalDuration = newBooking.RentalDuration,
                customerName = newBooking.CustomerName,
                price = newBooking.Price,
                dailyBookingNumber = newBooking.DailyBookingNumber,
                status = newBooking.Status
            });

            SuccessMessage = "✅ Đặt phòng thành công!";
            return RedirectToPage("/Rooms/Invoice", new { area = "Identity", bookingId });
        }


        private async Task<bool> IsOverlappingBookingAsync(BookingInputModel booking)
        {
            using var conn = new SqlConnection(ConnectionString);
            await conn.OpenAsync();

            string query = @"
                SELECT COUNT(*) FROM Bookings
                WHERE RoomId = @RoomId
                  AND RentalDate = @RentalDate
                  AND Status IN (N'pending', N'booked')
                  AND (
                    DATEPART(HOUR, StartTime) * 60 + DATEPART(MINUTE, StartTime) < @EndMinutes
                    AND DATEPART(HOUR, StartTime) * 60 + DATEPART(MINUTE, StartTime) + RentalDuration * 60 > @StartMinutes
                  )";

            using var cmd = new SqlCommand(query, conn);

            int startMinutes = (int)booking.StartTime.TotalMinutes;
            int endMinutes = startMinutes + booking.RentalDuration * 60;

            cmd.Parameters.AddWithValue("@RoomId", booking.RoomId);
            cmd.Parameters.AddWithValue("@RentalDate", booking.RentalDate);
            cmd.Parameters.AddWithValue("@StartMinutes", startMinutes);
            cmd.Parameters.AddWithValue("@EndMinutes", endMinutes);

            var result = (int)await cmd.ExecuteScalarAsync();
            return result > 0;
        }

        private int GetNextDailyBookingNumber(DateTime rentalDate)
        {
            using var conn = new SqlConnection(ConnectionString);
            conn.Open();

            string sql = "SELECT ISNULL(MAX(DailyBookingNumber), 0) FROM Bookings WHERE RentalDate = @RentalDate";

            using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@RentalDate", rentalDate.Date);

            var result = cmd.ExecuteScalar();
            return (int)result + 1;
        }

        private int SaveBooking(BookingInputModel booking, int price, int dailyBookingNumber)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();

                const string sql = @"
INSERT INTO Bookings
(CustomerName, CustomerPhone, CustomerEmail, RentalDate, StartTime,
 RentalDuration, RoomId, GuestCount, Price, Status, CreatedAt, UpdatedAt, DailyBookingNumber, IsArchived)
VALUES
(@CustomerName, @CustomerPhone, @CustomerEmail, @RentalDate, @StartTime,
 @RentalDuration, @RoomId, @GuestCount, @Price, @Status, @CreatedAt, @UpdatedAt, @DailyBookingNumber, @IsArchived);


            SELECT CAST(SCOPE_IDENTITY() AS INT);";

                using var cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@CustomerName", booking.CustomerName);
                cmd.Parameters.AddWithValue("@CustomerPhone", booking.CustomerPhone);
                cmd.Parameters.AddWithValue("@CustomerEmail", booking.CustomerEmail);
                cmd.Parameters.AddWithValue("@RentalDate", booking.RentalDate);
                cmd.Parameters.Add("@StartTime", System.Data.SqlDbType.Time).Value = booking.StartTime;
                cmd.Parameters.AddWithValue("@RentalDuration", booking.RentalDuration);
                cmd.Parameters.AddWithValue("@RoomId", booking.RoomId);
                cmd.Parameters.AddWithValue("@GuestCount", booking.GuestCount);
                cmd.Parameters.AddWithValue("@Price", price);
                cmd.Parameters.AddWithValue("@Status", "pending");
                cmd.Parameters.AddWithValue("@CreatedAt", DateTime.Now);
                cmd.Parameters.AddWithValue("@UpdatedAt", DateTime.Now);
                cmd.Parameters.AddWithValue("@DailyBookingNumber", dailyBookingNumber);
                cmd.Parameters.AddWithValue("@IsArchived", false); // 👈 Dòng này giải quyết lỗi


                var result = cmd.ExecuteScalar();
                return result == null ? 0 : (int)result;
            }
            catch (Exception ex)
            {
                ModelState.AddModelError(string.Empty, $"Lỗi lưu booking: {ex.Message}");
                return 0;
            }
        }

        private int CalculatePrice(BookingInputModel booking)
        {
            string room = (booking.RoomId ?? "A").Trim().ToUpper();

            int maxGuests = room switch
            {
                "B" => 20,
                "C" => 30,
                _ => 10
            };

            int extraGuests = Math.Max(0, booking.GuestCount - maxGuests);
            int surcharge = extraGuests * 30_000;

            bool isWeekend = booking.RentalDate.DayOfWeek == DayOfWeek.Saturday
                             || booking.RentalDate.DayOfWeek == DayOfWeek.Sunday;

            bool isGoldenHour = booking.StartHour >= 14 && booking.StartHour < 17;

            int unitPrice = room switch
            {
                "B" => isGoldenHour ? 240_000 : (isWeekend ? 400_000 : 360_000),
                "C" => isGoldenHour ? 360_000 : (isWeekend ? 600_000 : 540_000),
                _ => isGoldenHour ? 120_000 : (isWeekend ? 200_000 : 180_000),
            };

            int totalPrice = unitPrice * booking.RentalDuration + surcharge;

            return totalPrice;
        }

        public class BookingInputModel
        {
            [Required(ErrorMessage = "Vui lòng nhập họ tên.")]
            public string CustomerName { get; set; } = string.Empty;

            [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
            [Phone(ErrorMessage = "Số điện thoại không hợp lệ.")]
            public string CustomerPhone { get; set; } = string.Empty;

            [Required(ErrorMessage = "Vui lòng nhập email.")]
            [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
            public string CustomerEmail { get; set; } = string.Empty;

            [Required(ErrorMessage = "Vui lòng chọn ngày thuê.")]
            [DataType(DataType.Date)]
            public DateTime RentalDate { get; set; }

            [Range(8, 22, ErrorMessage = "Chỉ chọn giờ 08‑22")]
            public int StartHour { get; set; }

            [Required(ErrorMessage = "Vui lòng chọn giờ bắt đầu thuê.")]
            public TimeSpan StartTime { get; set; }

            [Required(ErrorMessage = "Vui lòng nhập thời gian thuê.")]
            [Range(1, 14, ErrorMessage = "Thời gian thuê tối đa 14 giờ.")]
            public int RentalDuration { get; set; }

            [Required(ErrorMessage = "Vui lòng nhập tên phòng.")]
            public string RoomId { get; set; } = "A";

            [Required(ErrorMessage = "Vui lòng nhập số lượng khách.")]
            [Range(1, int.MaxValue, ErrorMessage = "Số lượng khách phải lớn hơn hoặc bằng 1.")]
            public int GuestCount { get; set; }
        }
    }
}
