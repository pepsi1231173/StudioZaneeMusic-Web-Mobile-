using DuAnBai3.Models;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;

namespace DuAnBai3.Controllers
{
    public class RoomController : Controller
    {
        // Danh sách tạm thời các phòng
        private static readonly List<Room> rooms = new List<Room>
        {
            new Room { Id = 1, Name = "Phòng A" },
            new Room { Id = 2, Name = "Phòng B" },
            new Room { Id = 3, Name = "Phòng C" }
        };

        // GET: /Room/Index
        public IActionResult Index()
        {
            return View(rooms); // Truyền danh sách phòng sang view
        }

        // GET: /Room/Book?room_id=1
        public IActionResult Book(int room_id)
        {
            var selectedRoom = rooms.Find(r => r.Id == room_id);

            if (selectedRoom == null)
            {
                return NotFound(); // Trả về 404 nếu phòng không tồn tại
            }

            ViewBag.Room = selectedRoom;
            return View();
        }
    }
}
