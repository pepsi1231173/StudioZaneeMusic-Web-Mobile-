using Microsoft.AspNetCore.Mvc;

namespace DuAnBai3.Controllers
{
    public class ServicesController : Controller
    {
        public IActionResult Recording()
        {
            return View();
        }

        public IActionResult Studio()
        {
            return View();
        }

        public IActionResult Instruments()
        {
            return View();
        }

        // Bạn có thể thêm MakeMusic như ở phần trước
        public IActionResult MakeMusic()
        {
            return View();
        }
    }
}
