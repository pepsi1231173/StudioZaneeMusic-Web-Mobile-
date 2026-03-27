using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DuAnBai3.Controllers
{
    public class ContactController : Controller
    {
        [HttpGet]
        [AllowAnonymous]  // Cho phép truy cập không cần đăng nhập
        public IActionResult Index()
        {
            return View();
        }
    }
}
