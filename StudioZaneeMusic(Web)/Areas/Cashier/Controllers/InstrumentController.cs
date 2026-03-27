using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DuAnBai3.Areas.Cashier.Controllers
{
    [Area("Cashier")]
    [Authorize(Roles = "cashier")]
    public class InstrumentController : Controller
    {
        public IActionResult Index()
        {
            // Hiển thị danh sách đơn thuê nhạc cụ cần xử lý
            return View();
        }
    }
}
