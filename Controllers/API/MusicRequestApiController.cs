using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using DuAnBai3.Data; // ✅ thiếu namespace này
using System.Linq;

namespace DuAnBai3.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class MusicRequestApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public MusicRequestApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ Lấy tất cả yêu cầu nhạc
        [HttpGet]
        public IActionResult GetAll()
        {
            var requests = _context.MusicRequests.OrderByDescending(r => r.CreatedAt).ToList();
            return Ok(requests);
        }

        // ✅ Lấy yêu cầu theo ID
        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            var request = _context.MusicRequests.FirstOrDefault(r => r.Id == id);
            if (request == null)
                return NotFound(new { message = "Không tìm thấy yêu cầu" });

            return Ok(request);
        }

        // ✅ Tạo yêu cầu mới
        [HttpPost]
        public IActionResult Create([FromBody] MusicRequest request)
        {
            if (request == null)
                return BadRequest(new { message = "Dữ liệu không hợp lệ" });

            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            request.CreatedAt = DateTime.Now;
            request.Status = "pending";
            _context.MusicRequests.Add(request);
            _context.SaveChanges();

            return CreatedAtAction(nameof(GetById), new { id = request.Id }, request);
        }

        // ✅ Cập nhật trạng thái (vd: approved / rejected)
        [HttpPut("{id}")]
        public IActionResult Update(int id, [FromBody] MusicRequest updated)
        {
            var request = _context.MusicRequests.FirstOrDefault(r => r.Id == id);
            if (request == null)
                return NotFound(new { message = "Không tìm thấy yêu cầu" });

            request.Status = updated.Status ?? request.Status;
            _context.SaveChanges();

            return Ok(request);
        }

        // ✅ Xóa yêu cầu
        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var request = _context.MusicRequests.FirstOrDefault(r => r.Id == id);
            if (request == null)
                return NotFound(new { message = "Không tìm thấy yêu cầu" });

            _context.MusicRequests.Remove(request);
            _context.SaveChanges();
            return NoContent();
        }
        // ✅ Lấy yêu cầu theo email khách hàng
        [HttpGet("by-email/{email}")]
        public IActionResult GetByEmail(string email)
        {
            var requests = _context.MusicRequests
                .Where(r => r.CustomerEmail == email)
                .OrderByDescending(r => r.CreatedAt)
                .ToList();

            if (!requests.Any())
                return NotFound(new { message = "Không có yêu cầu nào cho email này" });

            return Ok(requests);
        }

    }
}