using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DuAnBai3.Areas.Cashier.Controllers
{
    [Area("Cashier")]
    [Authorize(Roles = "cashier")]
    public class InvoiceController : Controller
    {
        public IActionResult Index()
        {
            // Trang tổng quản lý hóa đơn: tạo, xem, in, chỉnh sửa
            return View();
        }

        public IActionResult Create()
        {
            // Tạo hóa đơn mới
            return View();
        }

        public IActionResult Details(int id)
        {
            // Xem chi tiết hóa đơn
            return View();
        }

        public IActionResult Print(int id)
        {
            // In lại hóa đơn
            return View();
        }

        public IActionResult Edit(int id)
        {
            // Chỉnh sửa ghi chú hóa đơn (nếu được phân quyền)
            return View();
        }
    }
}
