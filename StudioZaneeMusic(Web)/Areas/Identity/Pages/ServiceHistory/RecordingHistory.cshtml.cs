using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;

namespace DuAnBai3.Pages
{
    public class ServiceHistoryModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public ServiceHistoryModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string Username { get; set; }
        public string UserId { get; set; }
        public string UserEmail { get; set; }

        public List<BookingInfo> BookingHistory { get; set; } = new();
        public List<InstrumentRental> InstrumentHistory { get; set; } = new();
        public List<RecordingSession> RecordingHistory { get; set; } = new();
        public List<MusicRequest> MusicRequestHistory { get; set; } = new();

        public IActionResult OnGet()
        {
            Username = User.Identity?.Name;

            if (string.IsNullOrEmpty(Username))
            {
                TempData["ErrorMessage"] = "Bạn cần đăng nhập để xem lịch sử dịch vụ.";
                return RedirectToPage("/Account/Login");
            }

            string connectionString = _configuration.GetConnectionString("DefaultConnection");

            using var conn = new SqlConnection(connectionString);
            conn.Open();

            // 1️⃣ Lấy UserId & Email
            using (var cmd = new SqlCommand("SELECT Id, Email FROM AspNetUsers WHERE UserName = @username", conn))
            {
                cmd.Parameters.AddWithValue("@username", Username);
                using var reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    UserId = reader.GetString(0);
                    UserEmail = reader.GetString(1);
                }
                else
                {
                    TempData["ErrorMessage"] = "Không tìm thấy thông tin tài khoản.";
                    return RedirectToPage("/Index");
                }
            }

            // 2️⃣ Lịch sử thuê phòng
            using (var cmd = new SqlCommand(@"
    SELECT id, RoomId, RentalDate, StartTime, RentalDuration, Status, Price
    FROM bookings
    WHERE CustomerEmail = @user_email
    ORDER BY RentalDate DESC", conn))
            {
                cmd.Parameters.AddWithValue("@user_email", UserEmail);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    BookingHistory.Add(new BookingInfo
                    {
                        Id = reader.GetInt32(0),
                        RoomId = reader.GetString(1),
                        RentalDate = reader.GetDateTime(2),
                        StartTime = reader.GetTimeSpan(3),
                        RentalDuration = reader.GetInt32(4),
                        Status = reader.GetString(5),
                        Price = reader.GetInt32(6)  // <-- quan trọng: gán giá từ DB
                    });
                }
            }

            // 3️⃣ Lịch sử thuê nhạc cụ
            var allInstrumentIds = new HashSet<int>();
            var tempRentals = new List<(int Id, DateTime RentalDate, List<int> InstrumentIds, int TotalPrice, string Status)>();

            using (var cmd = new SqlCommand(@"
    SELECT Id, RentalDate, SelectedInstruments, TotalPrice, Status
    FROM InstrumentRentals
    WHERE CustomerEmail = @user_email
    ORDER BY RentalDate DESC", conn))
            {
                cmd.Parameters.AddWithValue("@user_email", UserEmail);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    int id = reader.GetInt32(0);
                    DateTime rentalDate = reader.IsDBNull(1) ? DateTime.MinValue : reader.GetDateTime(1);
                    string json = reader.IsDBNull(2) ? "[]" : reader.GetString(2);
                    int totalPrice = reader.IsDBNull(3) ? 0 : reader.GetInt32(3);
                    string status = reader.IsDBNull(4) ? "Pending" : reader.GetString(4);

                    List<int> instrumentIds;
                    try
                    {
                        instrumentIds = JsonSerializer.Deserialize<List<int>>(json) ?? new List<int>();
                    }
                    catch
                    {
                        instrumentIds = new List<int>();
                    }

                    foreach (var insId in instrumentIds)
                        allInstrumentIds.Add(insId);

                    tempRentals.Add((id, rentalDate, instrumentIds, totalPrice, status));
                }
            }

            // 4️⃣ Lấy thông tin tên và hình ảnh nhạc cụ
            Dictionary<int, (string Name, string ImageUrl)> instrumentMap = new();
            if (allInstrumentIds.Count > 0)
            {
                string paramList = string.Join(",", allInstrumentIds.Select((_, i) => $"@p{i}"));
                string sql = $"SELECT Id, Name, ImageUrl FROM Products WHERE Id IN ({paramList})";

                using var cmd = new SqlCommand(sql, conn);
                int idx = 0;
                foreach (var insId in allInstrumentIds)
                    cmd.Parameters.AddWithValue($"@p{idx++}", insId);

                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    int id = reader.GetInt32(0);
                    string name = reader.GetString(1);
                    string imageUrl = reader.IsDBNull(2) ? "" : reader.GetString(2);
                    instrumentMap[id] = (name, imageUrl);
                }
            }

            // 5️⃣ Gán tên, hình, giá, trạng thái vào lịch sử nhạc cụ
            foreach (var rental in tempRentals)
            {
                string names = string.Join(", ", rental.InstrumentIds.Select(id => instrumentMap.ContainsKey(id) ? instrumentMap[id].Name : $"ID {id}"));
                string images = string.Join(",", rental.InstrumentIds.Select(id => instrumentMap.ContainsKey(id) ? instrumentMap[id].ImageUrl : ""));

                InstrumentHistory.Add(new InstrumentRental
                {
                    Id = rental.Id,
                    RentalDate = rental.RentalDate,
                    InstrumentName = names,
                    InstrumentImage = images,
                    Price = rental.TotalPrice,
                    Status = rental.Status
                });
            }



            // 6️⃣ Lịch sử thu âm
            using (var cmd = new SqlCommand(@"
                SELECT Id, RecordingDate, RecordingTime, RecordingPackage, Price, Status
                FROM RecordingBookings
                WHERE CustomerEmail = @user_email
                ORDER BY RecordingDate DESC", conn))
            {
                cmd.Parameters.AddWithValue("@user_email", UserEmail);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    RecordingHistory.Add(new RecordingSession
                    {
                        Id = reader.GetInt32(0),
                        SessionDate = reader.GetDateTime(1),
                        StartTime = reader.GetTimeSpan(2),
                        EndTime = reader.GetTimeSpan(2).Add(TimeSpan.FromHours(1)), // giả sử 1h mặc định
                        RecordingPackage = reader.GetString(3),
                        Price = reader.GetInt32(4),
                        Status = reader.GetString(5)
                    });
                }
            }

            // 7️⃣ Lịch sử làm nhạc
            using (var cmd = new SqlCommand(@"
                SELECT Id, CreatedAt, Status, MusicGenre, MusicDescription
                FROM MusicRequests
                WHERE CustomerEmail = @user_email
                ORDER BY CreatedAt DESC", conn))
            {
                cmd.Parameters.AddWithValue("@user_email", UserEmail);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    MusicRequestHistory.Add(new MusicRequest
                    {
                        Id = reader.GetInt32(0),
                        RequestDate = reader.GetDateTime(1),
                        Status = reader.GetString(2),
                        MusicGenre = reader.GetString(3),
                        MusicDescription = reader.GetString(4)
                    });
                }
            }

            return Page();
        }

        // ========== MODELS ==========
        public class BookingInfo
        {
            public int Id { get; set; }
            public string RoomId { get; set; }
            public DateTime RentalDate { get; set; }
            public TimeSpan StartTime { get; set; }
            public int RentalDuration { get; set; } // số giờ thuê
            public int Price { get; set; }
            public string Status { get; set; } = "pending";


            // Tính giờ kết thúc tự động
            public TimeSpan EndTime => StartTime + TimeSpan.FromHours(RentalDuration);
        }

        public class InstrumentRental
        {
            public int Id { get; set; }
            public DateTime RentalDate { get; set; }
            public string InstrumentName { get; set; } = "";
            public string InstrumentImage { get; set; } = ""; // nhiều hình cách nhau bằng dấu ,
            public int Price { get; set; } = 0;
            public string Status { get; set; } = "Pending";
        }


        public class RecordingSession
        {
            public int Id { get; set; }
            public DateTime SessionDate { get; set; }
            public TimeSpan StartTime { get; set; }
            public TimeSpan EndTime { get; set; }
            public string RecordingPackage { get; set; }
            public int Price { get; set; }
            public string Status { get; set; }
            public string StartTimeStr => StartTime.ToString(@"hh\:mm");
            public string EndTimeStr => EndTime.ToString(@"hh\:mm");
        }

        public class MusicRequest
        {
            public int Id { get; set; }
            public DateTime RequestDate { get; set; }
            public string Status { get; set; }
            public string MusicGenre { get; set; }
            public string MusicDescription { get; set; }
        }
    }
}
