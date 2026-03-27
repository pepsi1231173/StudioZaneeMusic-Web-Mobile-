using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using DuAnBai3.Models;

namespace DuAnBai3.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class StatisticsController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        // ✅ CHỈ dùng 1 constructor chứa tất cả dependencies
        public StatisticsController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            var totalBookings = await _context.Bookings.CountAsync();
            var totalInstruments = await _context.InstrumentRentals.CountAsync();
            var totalMusicRequests = await _context.MusicRequests.CountAsync();
            var totalRecordings = await _context.RecordingBookings.CountAsync();

            var successfulBookings = await _context.Bookings
                .Where(b => b.Status == "booked")
                .ToListAsync();

            decimal totalRevenue = successfulBookings.Sum(b => b.Price);
            int totalBooked = successfulBookings.Count;

            // Tính tổng người dùng không có role Admin
            var allUsers = await _userManager.Users.ToListAsync();
            int totalUsers = 0;
            foreach (var user in allUsers)
            {
                var roles = await _userManager.GetRolesAsync(user);
                if (!roles.Contains("Admin"))
                {
                    totalUsers++;
                }
            }

            ViewBag.TotalRevenue = totalRevenue;
            ViewBag.TotalBookings = totalBookings;
            ViewBag.TotalBooked = totalBooked;
            ViewBag.TotalInstruments = totalInstruments;
            ViewBag.TotalMusicRequests = totalMusicRequests;
            ViewBag.TotalRecordings = totalRecordings;
            ViewBag.TotalUsers = totalUsers;

            ViewBag.ChartData = new
            {
                labels = new[] { "Phòng", "Nhạc cụ", "Yêu cầu bài hát", "Ghi âm" },
                counts = new[] { totalBookings, totalInstruments, totalMusicRequests, totalRecordings }
            };

            return View();
        }
    }
}
