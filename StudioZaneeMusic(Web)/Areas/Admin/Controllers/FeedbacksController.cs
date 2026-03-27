using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using System.Linq;

namespace DuAnBai3.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class FeedbacksController : Controller
    {
        private readonly ApplicationDbContext _context;

        public FeedbacksController(ApplicationDbContext context)
        {
            _context = context;
        }

        // API lấy số lượng feedback mới
        [HttpGet]
        public IActionResult GetNewFeedbackCount()
        {
            var count = _context.Feedbacks.Where(f => f.IsNew).Count();
            return Json(new { count });
        }

        // Trang quản lý feedback
        public IActionResult Index()
        {
            var feedbacks = _context.Feedbacks
                                    .OrderByDescending(f => f.CreatedAt)
                                    .ToList();

            // Đánh dấu tất cả feedback mới là đã xem
            feedbacks.ForEach(f => f.IsNew = false);
            _context.SaveChanges();

            ViewData["Title"] = "Quản lý Feedback";
            return View(feedbacks);
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Delete(int id)
        {
            var feedback = _context.Feedbacks.Find(id);
            if (feedback == null)
                return NotFound();

            _context.Feedbacks.Remove(feedback);
            _context.SaveChanges();
            return Ok();
        }

        // API lấy token
        [HttpGet]
        public IActionResult GetAntiforgeryToken()
        {
            var tokens = HttpContext.RequestServices.GetService<Microsoft.AspNetCore.Antiforgery.IAntiforgery>();
            var tokenSet = tokens.GetAndStoreTokens(HttpContext);
            return Json(new { token = tokenSet.RequestToken });
        }


    }
}
