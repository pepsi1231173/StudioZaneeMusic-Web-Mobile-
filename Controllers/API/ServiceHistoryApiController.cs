using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;

namespace DuAnBai3.Controllers.Api
{
    [ApiController]
    [Route("api/[controller]")]
    public class ServiceHistoryApiController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public ServiceHistoryApiController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpGet("{email}")]
        public IActionResult GetServiceHistory(string email)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");

            var result = new
            {
                BookingHistory = new List<object>(),
                InstrumentHistory = new List<object>(),
                RecordingHistory = new List<object>(),
                MusicRequestHistory = new List<object>()
            };

            using var conn = new SqlConnection(connectionString);
            conn.Open();

            // 1️⃣ Lịch sử thuê phòng
            using (var cmd = new SqlCommand(@"
                SELECT Id, RoomId, RentalDate, StartTime, EndTime, Status, Price
                FROM Bookings 
                WHERE CustomerEmail = @email
                ORDER BY RentalDate DESC", conn))
            {
                cmd.Parameters.AddWithValue("@email", email);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    result.BookingHistory.Add(new
                    {
                        Id = reader.GetInt32(0),
                        RoomId = reader.GetString(1),
                        RentalDate = reader.GetDateTime(2).ToString("dd/MM/yyyy"), // ✅ format ngày
                        StartTime = reader.GetTimeSpan(3).ToString(@"hh\:mm"),
                        EndTime = reader.GetTimeSpan(4).ToString(@"hh\:mm"),
                        Status = reader.GetString(5),
                        Price = reader.GetInt32(6)
                    });
                }
            }

            // 2️⃣ Lịch sử thuê nhạc cụ
            var allInstrumentIds = new HashSet<int>();
            var tempRentals = new List<(int Id, DateTime RentalDate, List<int> InsIds, int Price, string Status)>();

            using (var cmd = new SqlCommand(@"
                SELECT Id, RentalDate, SelectedInstruments, TotalPrice, Status
                FROM InstrumentRentals
                WHERE CustomerEmail = @email
                ORDER BY RentalDate DESC", conn))
            {
                cmd.Parameters.AddWithValue("@email", email);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    var ids = JsonSerializer.Deserialize<List<int>>(reader.GetString(2)) ?? new();
                    foreach (var id in ids) allInstrumentIds.Add(id);

                    tempRentals.Add((
                        reader.GetInt32(0),
                        reader.GetDateTime(1),
                        ids,
                        reader.GetInt32(3),
                        reader.GetString(4)
                    ));
                }
            }

            // 🔹 Lấy thông tin nhạc cụ từ bảng Products
            var instrumentMap = new Dictionary<int, (string Name, string ImageUrl)>();
            if (allInstrumentIds.Any())
            {
                var paramList = string.Join(",", allInstrumentIds.Select((_, i) => $"@p{i}"));
                var sql = $"SELECT Id, Name, ImageUrl FROM Products WHERE Id IN ({paramList})";

                using var cmd = new SqlCommand(sql, conn);
                int i = 0;
                foreach (var id in allInstrumentIds)
                    cmd.Parameters.AddWithValue($"@p{i++}", id);

                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                    instrumentMap[reader.GetInt32(0)] = (reader.GetString(1), reader.GetString(2));
            }

            foreach (var rental in tempRentals)
            {
                var names = string.Join(", ", rental.InsIds.Select(id => instrumentMap.ContainsKey(id) ? instrumentMap[id].Name : "N/A"));
                var imgs = string.Join(",", rental.InsIds.Select(id => instrumentMap.ContainsKey(id) ? instrumentMap[id].ImageUrl : ""));
                result.InstrumentHistory.Add(new
                {
                    rental.Id,
                    RentalDate = rental.RentalDate.ToString("dd/MM/yyyy"), // ✅ format ngày
                    rental.Price,
                    rental.Status,
                    InstrumentName = names,
                    InstrumentImage = imgs
                });
            }

            // 3️⃣ Lịch sử thu âm
            using (var cmd = new SqlCommand(@"
                SELECT Id, RecordingPackage, RecordingDate, RecordingTime, Duration, Price, Status
                FROM RecordingBookings
                WHERE CustomerEmail = @email
                ORDER BY RecordingDate DESC", conn))
            {
                cmd.Parameters.AddWithValue("@email", email);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    var startTime = reader.GetTimeSpan(3);
                    var duration = reader.GetInt32(4);
                    var endTime = startTime.Add(TimeSpan.FromHours(duration));

                    result.RecordingHistory.Add(new
                    {
                        Id = reader.GetInt32(0),
                        RecordingPackage = reader.GetString(1),
                        RecordingDate = reader.GetDateTime(2).ToString("dd/MM/yyyy"), // ✅ format ngày
                        StartTime = startTime.ToString(@"hh\:mm"),
                        EndTime = endTime.ToString(@"hh\:mm"),
                        Price = reader.GetInt32(5),
                        Status = reader.GetString(6)
                    });
                }
            }

            // 4️⃣ Lịch sử làm nhạc
            using (var cmd = new SqlCommand(@"
                SELECT Id, CreatedAt, MusicGenre, MusicDescription, Status
                FROM MusicRequests
                WHERE CustomerEmail = @email
                ORDER BY CreatedAt DESC", conn))
            {
                cmd.Parameters.AddWithValue("@email", email);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    result.MusicRequestHistory.Add(new
                    {
                        Id = reader.GetInt32(0),
                        RequestDate = reader.GetDateTime(1).ToString("dd/MM/yyyy"), // ✅ format ngày
                        MusicGenre = reader.GetString(2),
                        MusicDescription = reader.GetString(3),
                        Status = reader.GetString(4)
                    });
                }
            }

            return Ok(result);
        }
    }
}
