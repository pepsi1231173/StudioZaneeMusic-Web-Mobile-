using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using System;

namespace DuAnBai3.Pages
{
    public class ConfirmModel : PageModel
    {
        private readonly string connectionString = "Server=LAPTOP-KS75264J\\SQLEXPRESS;Database=ĐACS;Trusted_Connection=True;TrustServerCertificate=True";

        [BindProperty(SupportsGet = true)]
        public string RoomId { get; set; }
        [BindProperty(SupportsGet = true)]
        public string CustomerName { get; set; }
        [BindProperty(SupportsGet = true)]
        public string CustomerPhone { get; set; }
        [BindProperty(SupportsGet = true)]
        public string CustomerEmail { get; set; }
        [BindProperty(SupportsGet = true)]
        public string RentalDate { get; set; }
        [BindProperty(SupportsGet = true)]
        public string StartTime { get; set; }
        [BindProperty(SupportsGet = true)]
        public int RentalDuration { get; set; }
        [BindProperty(SupportsGet = true)]
        public int GuestCount { get; set; } = 1;

        public string Message { get; set; }

        public IActionResult OnGet()
        {
            if (string.IsNullOrEmpty(RoomId) || string.IsNullOrEmpty(CustomerName) ||
                string.IsNullOrEmpty(CustomerPhone) || string.IsNullOrEmpty(CustomerEmail) ||
                string.IsNullOrEmpty(RentalDate) || string.IsNullOrEmpty(StartTime) ||
                RentalDuration <= 0)
            {
                Message = "❌ Dữ liệu không hợp lệ.";
                return Page();
            }

            if (!DateTime.TryParse(RentalDate, out DateTime rentalDateParsed) ||
                !TimeSpan.TryParse(StartTime, out TimeSpan startTimeParsed))
            {
                Message = "❌ Định dạng ngày hoặc giờ không hợp lệ.";
                return Page();
            }

            // Kiểm tra ngày thuê >= hôm nay
            if (rentalDateParsed.Date < DateTime.Today)
            {
                Message = "❌ Ngày thuê phải là hôm nay hoặc tương lai.";
                return Page();
            }

            // Giờ bắt đầu từ 08:00 đến 22:00
            if (startTimeParsed < TimeSpan.FromHours(8) || startTimeParsed > TimeSpan.FromHours(22))
            {
                Message = "❌ Giờ bắt đầu phải nằm trong khoảng từ 08:00 đến 22:00.";
                return Page();
            }

            // Kiểm tra số giờ thuê hợp lệ (giờ kết thúc <= 23:00)
            TimeSpan endTime = startTimeParsed + TimeSpan.FromHours(RentalDuration);
            if (endTime > TimeSpan.FromHours(23))
            {
                Message = "❌ Thời gian thuê không được vượt quá 23:00.";
                return Page();
            }

            // Kiểm tra trùng lịch
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();

                string checkSql = @"
                    SELECT COUNT(*) FROM bookings 
                    WHERE room_id = @RoomId 
                      AND rental_date = @RentalDate 
                      AND status IN (N'pending', N'booked')
                      AND (
                          DATEPART(HOUR, start_time) * 60 + DATEPART(MINUTE, start_time) < @EndMinutes
                          AND DATEPART(HOUR, start_time) * 60 + DATEPART(MINUTE, start_time) + rental_duration * 60 > @StartMinutes
                      )";

                using (var checkCmd = new SqlCommand(checkSql, conn))
                {
                    int startMinutes = (int)startTimeParsed.TotalMinutes;
                    int endMinutes = startMinutes + RentalDuration * 60;

                    checkCmd.Parameters.AddWithValue("@RoomId", RoomId);
                    checkCmd.Parameters.AddWithValue("@RentalDate", rentalDateParsed);
                    checkCmd.Parameters.AddWithValue("@StartMinutes", startMinutes);
                    checkCmd.Parameters.AddWithValue("@EndMinutes", endMinutes);

                    int count = (int)checkCmd.ExecuteScalar();
                    if (count > 0)
                    {
                        Message = "❌ Phòng đã được đặt vào thời điểm này. Vui lòng chọn thời gian khác.";
                        return Page();
                    }
                }

                // Tính giá thuê
                int startHour = startTimeParsed.Hours;
                int price = CalculatePrice(RoomId, rentalDateParsed, startHour, RentalDuration, GuestCount);

                // Thêm vào bookings
                string insertSql = @"
                    INSERT INTO bookings 
                    (room_id, customer_name, customer_phone, customer_email, rental_date, start_time, end_time, rental_duration, guest_count, price, status, created_at, updated_at)
                    OUTPUT INSERTED.id
                    VALUES 
                    (@RoomId, @CustomerName, @CustomerPhone, @CustomerEmail, @RentalDate, @StartTime, @EndTime, @RentalDuration, @GuestCount, @Price, 'pending', GETDATE(), GETDATE())";

                using (var insertCmd = new SqlCommand(insertSql, conn))
                {
                    insertCmd.Parameters.AddWithValue("@RoomId", RoomId);
                    insertCmd.Parameters.AddWithValue("@CustomerName", CustomerName);
                    insertCmd.Parameters.AddWithValue("@CustomerPhone", CustomerPhone);
                    insertCmd.Parameters.AddWithValue("@CustomerEmail", CustomerEmail);
                    insertCmd.Parameters.AddWithValue("@RentalDate", rentalDateParsed);
                    insertCmd.Parameters.AddWithValue("@StartTime", startTimeParsed);
                    insertCmd.Parameters.AddWithValue("@EndTime", endTime);
                    insertCmd.Parameters.AddWithValue("@RentalDuration", RentalDuration);
                    insertCmd.Parameters.AddWithValue("@GuestCount", GuestCount);
                    insertCmd.Parameters.AddWithValue("@Price", price);

                    int newBookingId = (int)insertCmd.ExecuteScalar();

                    // Chuyển hướng sang trang invoice
                    return RedirectToPage("Invoice", new { BookingId = newBookingId });
                }
            }
        }

        // Hàm tính giá theo loại phòng, giờ vàng, cuối tuần, phụ thu khách vượt
        private int CalculatePrice(string roomId, DateTime rentalDate, int startHour, int duration, int guestCount)
        {
            string room = roomId.Trim().ToUpper();

            int maxGuests = room switch
            {
                "B" => 20,
                "C" => 30,
                _ => 10
            };

            int extraGuests = Math.Max(0, guestCount - maxGuests);
            int extraFee = extraGuests * 30000;

            bool isWeekend = rentalDate.DayOfWeek == DayOfWeek.Saturday || rentalDate.DayOfWeek == DayOfWeek.Sunday;

            int unitPriceNormal = room switch
            {
                "B" => isWeekend ? 400000 : 360000,
                "C" => isWeekend ? 600000 : 540000,
                _ => isWeekend ? 200000 : 180000,
            };

            int unitPriceGolden = room switch
            {
                "B" => 240000,
                "C" => 360000,
                _ => 120000,
            };

            int normalHours = 0;
            int goldenHours = 0;

            for (int i = 0; i < duration; i++)
            {
                int h = startHour + i;
                if (h >= 14 && h < 17)
                    goldenHours++;
                else
                    normalHours++;
            }

            int totalPrice = normalHours * unitPriceNormal + goldenHours * unitPriceGolden + extraFee;
            return totalPrice;
        }
    }
}


