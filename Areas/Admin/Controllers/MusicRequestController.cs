using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using System.Linq;

namespace DuAnBai3.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class MusicRequestController : Controller
    {
        private readonly ApplicationDbContext _context;

        public MusicRequestController(ApplicationDbContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            var requests = _context.MusicRequests.OrderByDescending(x => x.CreatedAt).ToList();
            return View(requests);
        }

        [HttpPost]
        public IActionResult Cancel(int id)
        {
            var req = _context.MusicRequests.Find(id);
            if (req != null && req.Status != "canceled")
            {
                req.Status = "canceled";
                _context.SaveChanges();
            }

            return RedirectToAction("Index");
        }
        [HttpPost]
        public IActionResult Confirm(int id)
        {
            var req = _context.MusicRequests.Find(id);
            if (req != null && req.Status != "confirmed")
            {
                req.Status = "confirmed";
                _context.SaveChanges();
            }

            return RedirectToAction("Index");
        }
        [HttpPost]
        public IActionResult Delete(int id)
        {
            var req = _context.MusicRequests.Find(id);
            if (req != null)
            {
                _context.MusicRequests.Remove(req);
                _context.SaveChanges();
            }

            return RedirectToAction("Index");
        }

    }
}
