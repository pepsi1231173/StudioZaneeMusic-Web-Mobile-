using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using Microsoft.EntityFrameworkCore;

namespace DuAnBai3.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FeedbackApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public FeedbackApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ [POST] /api/feedbackapi
        // Flutter gọi API này để gửi phản hồi
        [HttpPost]
        public async Task<IActionResult> PostFeedback([FromBody] Feedback feedback)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            feedback.CreatedAt = DateTime.Now;
            feedback.IsNew = true;
            _context.Feedbacks.Add(feedback);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Phản hồi đã được gửi thành công!",
                feedback.Id
            });
        }

        // ✅ [GET] /api/feedbackapi
        // Admin có thể xem tất cả phản hồi
        [HttpGet]
        public async Task<IActionResult> GetAllFeedbacks()
        {
            var feedbacks = await _context.Feedbacks
                .OrderByDescending(f => f.CreatedAt)
                .ToListAsync();

            return Ok(feedbacks);
        }

        // ✅ [PUT] /api/feedbackapi/{id}/mark-read
        // Admin có thể đánh dấu phản hồi đã xem
        [HttpPut("{id}/mark-read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var feedback = await _context.Feedbacks.FindAsync(id);
            if (feedback == null)
                return NotFound();

            feedback.IsNew = false;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã đánh dấu phản hồi là đã đọc" });
        }
    }
}