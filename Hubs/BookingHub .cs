using DuAnBai3.Models;
using DuAnBai3.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace DuAnBai3.Hubs
{
    [AllowAnonymous]
    public class BookingHub : Hub
    {
        private static Timer? _timer;
        private static Timer? _statusTimer;
        private readonly IHubContext<BookingHub> _hubContext;
        private readonly IConfiguration _configuration;
        private readonly MaintenanceService _maintenance;

        public BookingHub(IHubContext<BookingHub> hubContext, IConfiguration configuration, MaintenanceService maintenance)
        {
            _hubContext = hubContext;
            _configuration = configuration;
            _maintenance = maintenance;

            if (_timer == null)
            {
                _timer = new Timer(async _ =>
                {
                    string now = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss");
                    await _hubContext.Clients.All.SendAsync("ReceiveTime", now);
                }, null, TimeSpan.Zero, TimeSpan.FromSeconds(1));
            }

            if (_statusTimer == null)
            {
                _statusTimer = new Timer(async _ =>
                {
                    await UpdateBookingStatuses();
                }, null, TimeSpan.Zero, TimeSpan.FromSeconds(5));
            }
        }

        public override async Task OnConnectedAsync()
        {
            var maintenanceRooms = _maintenance.GetMaintenanceRooms();
            await Clients.Caller.SendAsync("MaintenanceUpdated", maintenanceRooms);
        }


        public async Task CreateBooking(BookingInputModel input)
        {
            if (_maintenance.IsInMaintenance(input.RoomId))
                throw new HubException($"Phòng {input.RoomId} đang bảo trì.");

            var rentalDate = input.RentalDate.Date;
            var startTime = TimeSpan.FromHours(input.StartHour);

            if (await IsOverlappingAsync(input.RoomId, rentalDate, startTime, input.RentalDuration))
                throw new HubException("Khung giờ đã bị đặt trước.");

            int price = CalculatePrice(input);
            int dailyBookingNumber = GetNextDailyBookingNumber(rentalDate);
            int bookingId = SaveBooking(input, price, dailyBookingNumber, startTime);

            await _hubContext.Clients.All.SendAsync("BookingCreated", new
            {
                id = bookingId,
                roomId = input.RoomId,
                rentalDate = rentalDate.ToString("yyyy-MM-dd"),
                startTime = $"{input.StartHour:D2}:00",
                rentalDuration = input.RentalDuration,
                status = "pending",
                customerName = input.CustomerName,
                price = price,
                dailyBookingNumber = dailyBookingNumber
            });
        }

        public async Task UpdateBookingStatus(int bookingId, string newStatus)
        {
            using var conn = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
            await conn.OpenAsync();

            string sql = @"
                UPDATE Bookings
                SET Status = @Status, UpdatedAt = @UpdatedAt
                WHERE Id = @Id;

                SELECT RoomId, RentalDate, StartTime, RentalDuration
                FROM Bookings
                WHERE Id = @Id;
            ";

            using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@Status", newStatus);
            cmd.Parameters.AddWithValue("@UpdatedAt", DateTime.Now);
            cmd.Parameters.AddWithValue("@Id", bookingId);

            using var reader = await cmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                string roomId = reader.GetString(0);
                DateTime date = reader.GetDateTime(1);
                TimeSpan startTime = reader.GetTimeSpan(2);
                int duration = reader.GetInt32(3);

                await _hubContext.Clients.All.SendAsync("BookingStatusChanged",
                    bookingId, roomId, date.ToString("yyyy-MM-dd"), startTime.Hours, duration, newStatus);
            }
        }

        private async Task<bool> IsOverlappingAsync(string roomId, DateTime rentalDate, TimeSpan startTime, int duration)
        {
            using var conn = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
            await conn.OpenAsync();

            int startMinutes = (int)startTime.TotalMinutes;
            int endMinutes = startMinutes + duration * 60;

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
            cmd.Parameters.AddWithValue("@RoomId", roomId);
            cmd.Parameters.AddWithValue("@RentalDate", rentalDate);
            cmd.Parameters.AddWithValue("@StartMinutes", startMinutes);
            cmd.Parameters.AddWithValue("@EndMinutes", endMinutes);

            int result = (int)await cmd.ExecuteScalarAsync();
            return result > 0;
        }

        private int GetNextDailyBookingNumber(DateTime rentalDate)
        {
            using var conn = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
            conn.Open();

            string sql = "SELECT ISNULL(MAX(DailyBookingNumber), 0) FROM Bookings WHERE RentalDate = @RentalDate";
            using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@RentalDate", rentalDate);

            int result = (int)cmd.ExecuteScalar();
            return result + 1;
        }

        private int SaveBooking(BookingInputModel input, int price, int dailyBookingNumber, TimeSpan startTime)
        {
            using var conn = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
            conn.Open();

            string sql = @"
                INSERT INTO Bookings
                (CustomerName, CustomerPhone, CustomerEmail, RentalDate, StartTime,
                 RentalDuration, RoomId, GuestCount, Price, Status, CreatedAt, UpdatedAt, DailyBookingNumber)
                VALUES
                (@CustomerName, @CustomerPhone, @CustomerEmail, @RentalDate, @StartTime,
                 @RentalDuration, @RoomId, @GuestCount, @Price, N'pending', @CreatedAt, @UpdatedAt, @DailyBookingNumber);
                SELECT SCOPE_IDENTITY();";

            using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@CustomerName", input.CustomerName);
            cmd.Parameters.AddWithValue("@CustomerPhone", input.CustomerPhone);
            cmd.Parameters.AddWithValue("@CustomerEmail", input.CustomerEmail);
            cmd.Parameters.AddWithValue("@RentalDate", input.RentalDate);
            cmd.Parameters.Add("@StartTime", System.Data.SqlDbType.Time).Value = startTime;
            cmd.Parameters.AddWithValue("@RentalDuration", input.RentalDuration);
            cmd.Parameters.AddWithValue("@RoomId", input.RoomId);
            cmd.Parameters.AddWithValue("@GuestCount", input.GuestCount);
            cmd.Parameters.AddWithValue("@Price", price);
            cmd.Parameters.AddWithValue("@CreatedAt", DateTime.Now);
            cmd.Parameters.AddWithValue("@UpdatedAt", DateTime.Now);
            cmd.Parameters.AddWithValue("@DailyBookingNumber", dailyBookingNumber);

            var result = cmd.ExecuteScalar();
            return result == null ? 0 : Convert.ToInt32(result);
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
            int surcharge = extraGuests * 30000;

            bool isWeekend = booking.RentalDate.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday;
            bool isGoldenHour = booking.StartHour >= 14 && booking.StartHour < 17;

            int unitPrice = room switch
            {
                "B" => isGoldenHour ? 240000 : (isWeekend ? 400000 : 360000),
                "C" => isGoldenHour ? 360000 : (isWeekend ? 600000 : 540000),
                _ => isGoldenHour ? 120000 : (isWeekend ? 200000 : 180000),
            };

            return unitPrice * booking.RentalDuration + surcharge;
        }

        private async Task UpdateBookingStatuses()
        {
            using var conn = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
            await conn.OpenAsync();

            string sql = @"
                UPDATE Bookings
                SET Status = N'active', UpdatedAt = GETDATE()
                OUTPUT inserted.Id, inserted.RoomId, inserted.RentalDate, inserted.StartTime, inserted.RentalDuration, 'active'
                WHERE Status = N'booked'
                  AND RentalDate = CAST(GETDATE() AS DATE)
                  AND DATEADD(MINUTE, 0, StartTime) <= CAST(GETDATE() AS TIME)
                  AND DATEADD(HOUR, RentalDuration, StartTime) > CAST(GETDATE() AS TIME);

                UPDATE Bookings
                SET Status = N'completed', UpdatedAt = GETDATE()
                OUTPUT inserted.Id, inserted.RoomId, inserted.RentalDate, inserted.StartTime, inserted.RentalDuration, 'completed'
                WHERE Status = N'active'
                  AND RentalDate = CAST(GETDATE() AS DATE)
                  AND DATEADD(HOUR, RentalDuration, StartTime) <= CAST(GETDATE() AS TIME);

                UPDATE Bookings
                SET Status = N'passed', UpdatedAt = GETDATE()
                OUTPUT inserted.Id, inserted.RoomId, inserted.RentalDate, inserted.StartTime, inserted.RentalDuration, 'passed'
                WHERE Status = N'pending'
                  AND RentalDate = CAST(GETDATE() AS DATE)
                  AND DATEADD(MINUTE, 0, StartTime) <= CAST(GETDATE() AS TIME);
            ";

            using var cmd = new SqlCommand(sql, conn);
            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                int id = reader.GetInt32(0);
                string roomId = reader.GetString(1);
                DateTime date = reader.GetDateTime(2);
                TimeSpan startTime = reader.GetTimeSpan(3);
                int duration = reader.GetInt32(4);
                string newStatus = reader.GetString(5);

                await _hubContext.Clients.All.SendAsync("BookingStatusChanged",
                    id, roomId, date.ToString("yyyy-MM-dd"), startTime.Hours, duration, newStatus);
            }
        }
        public async Task DeleteBooking(int bookingId)
        {
            using var conn = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
            await conn.OpenAsync();

            // Lấy thông tin booking trước khi xóa
            string selectSql = "SELECT RoomId, RentalDate, StartTime, RentalDuration FROM Bookings WHERE Id = @Id";
            using var selectCmd = new SqlCommand(selectSql, conn);
            selectCmd.Parameters.AddWithValue("@Id", bookingId);
            using var reader = await selectCmd.ExecuteReaderAsync();
            if (!await reader.ReadAsync()) return;

            string roomId = reader.GetString(0);
            DateTime rentalDate = reader.GetDateTime(1);
            TimeSpan startTime = reader.GetTimeSpan(2);
            int duration = reader.GetInt32(3);
            reader.Close();

            // Xóa booking
            string deleteSql = "DELETE FROM Bookings WHERE Id = @Id";
            using var deleteCmd = new SqlCommand(deleteSql, conn);
            deleteCmd.Parameters.AddWithValue("@Id", bookingId);
            await deleteCmd.ExecuteNonQueryAsync();

            // Phát sự kiện realtime
            await _hubContext.Clients.All.SendAsync("BookingDeleted",
                bookingId, roomId, rentalDate.ToString("yyyy-MM-dd"), startTime.Hours, duration);
        }

        public class BookingInputModel
        {
            public string CustomerName { get; set; } = string.Empty;
            public string CustomerPhone { get; set; } = string.Empty;
            public string CustomerEmail { get; set; } = string.Empty;
            public DateTime RentalDate { get; set; }
            public int StartHour { get; set; }
            public int RentalDuration { get; set; }
            public string RoomId { get; set; } = "A";
            public int GuestCount { get; set; } = 1;
        }
    }
}
