using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using DuAnBai3.Models;
using System;
using System.Collections.Generic;
using System.Linq;

namespace DuAnBai3.Pages.Rooms
{
    public class Lich_trongModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public Lich_trongModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [BindProperty(SupportsGet = true)]
        public string SelectedRoom { get; set; } = "A";

        public List<string> Rooms { get; } = new() { "A", "B", "C" };

        public List<DateTime> Days { get; private set; } = new();

        // Dữ liệu trạng thái từng ô giờ trong ngày: booking status hoặc maintenance
        public Dictionary<DateTime, Dictionary<int, string>> Bookings { get; } = new();

        // Chi tiết booking để check trạng thái active
        public Dictionary<DateTime, List<Booking>> BookingDetails { get; } = new();

        public void OnGet()
        {
            // Lấy 7 ngày tính từ hôm nay
            Days = Enumerable.Range(0, 7).Select(i => DateTime.Today.AddDays(i)).ToList();

            // Nếu phòng chọn không hợp lệ thì mặc định "A"
            if (string.IsNullOrWhiteSpace(SelectedRoom) || !Rooms.Contains(SelectedRoom))
                SelectedRoom = "A";

            LoadBookingData();
        }

        private void LoadBookingData()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");

            using SqlConnection conn = new(connStr);
            conn.Open();

            // Lấy booking có trạng thái: pending, booked, active, maintenance trong khoảng 7 ngày
            string sql = @"
SELECT Id, CustomerName, CustomerPhone, CustomerEmail,
       RentalDate, StartTime, RentalDuration, RoomId,
       GuestCount, Price, Status, CreatedAt, UpdatedAt
FROM Bookings
WHERE RoomId = @room
  AND Status IN (N'pending', N'booked', N'active', N'maintenance')
  AND CAST(RentalDate AS date) BETWEEN @from AND @to";

            using SqlCommand cmd = new(sql, conn);
            cmd.Parameters.AddWithValue("@room", SelectedRoom);
            cmd.Parameters.AddWithValue("@from", Days.First().Date);
            cmd.Parameters.AddWithValue("@to", Days.Last().Date);

            using SqlDataReader rd = cmd.ExecuteReader();

            while (rd.Read())
            {
                DateTime rentalDate = rd.GetDateTime(rd.GetOrdinal("RentalDate"));
                TimeSpan startTime = rd.GetTimeSpan(rd.GetOrdinal("StartTime"));
                int duration = rd.GetInt32(rd.GetOrdinal("RentalDuration"));
                string statusDb = rd.GetString(rd.GetOrdinal("Status")).ToLower();

                // Chuẩn hóa trạng thái
                string status = statusDb switch
                {
                    "pending" => "pending",
                    "booked" => "booked",
                    "active" => "active",
                    "maintenance" => "maintenance",
                    _ => "available"
                };

                if (!Bookings.TryGetValue(rentalDate.Date, out var hourMap))
                {
                    hourMap = new Dictionary<int, string>();
                    Bookings[rentalDate.Date] = hourMap;
                }

                for (int h = startTime.Hours; h < startTime.Hours + duration; h++)
                {
                    hourMap[h] = status;
                }

                if (!BookingDetails.TryGetValue(rentalDate.Date, out var list))
                {
                    list = new List<Booking>();
                    BookingDetails[rentalDate.Date] = list;
                }

                list.Add(new Booking
                {
                    Id = rd.GetInt32(rd.GetOrdinal("Id")),
                    CustomerName = rd.GetString(rd.GetOrdinal("CustomerName")),
                    CustomerPhone = rd.GetString(rd.GetOrdinal("CustomerPhone")),
                    CustomerEmail = rd.GetString(rd.GetOrdinal("CustomerEmail")),
                    RentalDate = rentalDate.Date,
                    StartTime = startTime,
                    RentalDuration = duration,
                    RoomId = SelectedRoom,
                    GuestCount = rd.GetInt32(rd.GetOrdinal("GuestCount")),
                    Price = rd.GetInt32(rd.GetOrdinal("Price")),
                    Status = status,
                    CreatedAt = rd.GetDateTime(rd.GetOrdinal("CreatedAt")),
                    UpdatedAt = rd.GetDateTime(rd.GetOrdinal("UpdatedAt"))
                });
            }
        }


        /// <summary>
        /// Lấy trạng thái booking (hoặc bảo trì) cho từng ô giờ trên lịch
        /// </summary>
        /// <param name="day">Ngày cần kiểm tra</param>
        /// <param name="hour">Giờ trong ngày (24h)</param>
        /// <returns>Trạng thái: pending, booked, active, maintenance, passed, available</returns>
        public string GetBookingStatus(DateTime day, int hour)
        {
            DateTime now = DateTime.Now;
            DateTime cellStart = day.Date.AddHours(hour);
            DateTime cellEnd = cellStart.AddHours(1);

            // Nếu thời gian ô giờ đã qua (với ngày hiện tại) thì trả về "passed"
            if (day.Date == now.Date && cellEnd <= now)
                return "passed";

            // Kiểm tra trạng thái bảo trì (maintenance) ưu tiên trả về ngay
            if (Bookings.TryGetValue(day.Date, out var hourMap) && hourMap.TryGetValue(hour, out var cachedStatus))
            {
                if (cachedStatus == "maintenance")
                    return "maintenance";
            }

            // Nếu có booking chi tiết cho ngày này
            if (BookingDetails.TryGetValue(day.Date, out var bookings))
            {
                // Các trạng thái ưu tiên theo thứ tự: pending > active > booked > khác
                string[] priorityStatuses = { "pending", "active", "booked" };

                foreach (var status in priorityStatuses)
                {
                    var booking = bookings.FirstOrDefault(bk =>
                    {
                        DateTime bkStart = bk.RentalDate.Date.Add(bk.StartTime);
                        DateTime bkEnd = bkStart.AddHours(bk.RentalDuration);
                        return bk.Status == status && cellStart < bkEnd && cellEnd > bkStart;
                    });

                    if (booking != null)
                        return status;
                }

                // Nếu không tìm được booking ưu tiên, kiểm tra có booking nào khác cho ô giờ này không
                var anyBooking = bookings.FirstOrDefault(bk =>
                {
                    DateTime bkStart = bk.RentalDate.Date.Add(bk.StartTime);
                    DateTime bkEnd = bkStart.AddHours(bk.RentalDuration);
                    return cellStart < bkEnd && cellEnd > bkStart;
                });

                if (anyBooking != null)
                    return anyBooking.Status;
            }

            // Nếu có trạng thái nào trong hourMap (ví dụ pending, booked...), trả về trạng thái đó
            if (Bookings.TryGetValue(day.Date, out hourMap) && hourMap.TryGetValue(hour, out var statusInMap))
                return statusInMap;

            // Mặc định là chưa đặt
            return "available";
        }

    }
}
