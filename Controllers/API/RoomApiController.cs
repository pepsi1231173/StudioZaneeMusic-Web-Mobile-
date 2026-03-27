using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using System.Linq;
using DuAnBai3.Models;

namespace DuAnBai3.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class RoomApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public RoomApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/RoomApi
        [HttpGet]
        public IActionResult GetAllRooms()
        {
            var rooms = _context.Rooms.ToList();
            return Ok(rooms);
        }

        // GET: api/RoomApi/5
        [HttpGet("{id}")]
        public IActionResult GetRoom(int id)
        {
            var room = _context.Rooms.FirstOrDefault(r => r.Id == id);
            if (room == null)
                return NotFound();
            return Ok(room);
        }
    }
}
