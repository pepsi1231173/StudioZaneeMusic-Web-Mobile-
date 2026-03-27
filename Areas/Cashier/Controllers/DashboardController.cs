using DuAnBai3.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Threading.Tasks;

namespace DuAnBai3.Areas.Cashier.Controllers
{
    [Area("Cashier")]
    public class DashboardController : Controller
    {
        private readonly SignInManager<ApplicationUser> _signInManager;

        public DashboardController(SignInManager<ApplicationUser> signInManager)
        {
            _signInManager = signInManager;
        }

        public IActionResult Index()
        {
            return View(); // Views/Cashier/Dashboard/Index.cshtml
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            await _signInManager.SignOutAsync();
            // Redirect về trang Login Identity
            return RedirectToAction("Login", "Account", new { area = "Identity" });
        }
    }
}
