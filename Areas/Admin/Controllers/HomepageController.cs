using DuAnBai3.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace DuAnBai3.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class HomepageController : Controller
    {
        private readonly SignInManager<ApplicationUser> _signInManager;
        public IActionResult Dashboard()
        {
            return View(); // sẽ tìm ở Areas/Admin/Views/Homepage/Dashboard.cshtml
        }
        

        public HomepageController(SignInManager<ApplicationUser> signInManager)
        {
            _signInManager = signInManager;
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            await _signInManager.SignOutAsync();
            return RedirectToPage("/Account/Login", new { area = "Identity" });
        }
    }
}
