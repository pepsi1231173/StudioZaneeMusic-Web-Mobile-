using Microsoft.AspNetCore.Mvc.RazorPages;
using DuAnBai3.Models;
using DuAnBai3.Services;
using System.Collections.Generic;

namespace DuAnBai3.Areas.Identity.Pages.Rooms
{
    public class IndexModel : PageModel
    {
        private readonly MaintenanceService _maintenanceService;

        public IndexModel(MaintenanceService maintenanceService)
        {
            _maintenanceService = maintenanceService;
        }

        // Danh sách phòng hiển thị lên giao diện
        public List<Room> Rooms { get; private set; } = new();

        // Danh sách tên phòng đang bảo trì (dùng để đánh dấu và ẩn nút đặt)
        public List<string> MaintenanceRooms { get; private set; } = new();

        public void OnGet()
        {
            // Giả lập dữ liệu phòng - có thể thay thế bằng truy vấn từ DB
            Rooms = new List<Room>
            {
                new Room
                {
                    Id = 1,
                    Name = "A",
                    Type = "STANDARD",
                    MaxPeople = 10,
                    WeekdayPrice = 180_000,
                    WeekendPrice = 200_000,
                    GoldenHourPrice = 120_000
                },
                new Room
                {
                    Id = 2,
                    Name = "B",
                    Type = "VIP",
                    MaxPeople = 20,
                    WeekdayPrice = 360_000,
                    WeekendPrice = 400_000,
                    GoldenHourPrice = 240_000
                },
                new Room
                {
                    Id = 3,
                    Name = "C",
                    Type = "SVIP",
                    MaxPeople = 30,
                    WeekdayPrice = 540_000,
                    WeekendPrice = 600_000,
                    GoldenHourPrice = 360_000
                }
            };

            // Lấy danh sách phòng đang bảo trì từ service singleton
            MaintenanceRooms = _maintenanceService.GetMaintenanceRooms();
        }
    }
}