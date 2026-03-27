using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Authorization;

namespace DuAnBai3.Areas.Admin.Pages.Product
{
    public class DashboardModel : PageModel
    {
        public bool ShowSuccess { get; set; }

        public string Username { get; set; }
        public string Email { get; set; }
        public string Role { get; set; }

        public void OnGet()
        {
            // Kiểm tra thông báo thành công
            if (TempData.ContainsKey("Success"))
            {
                ShowSuccess = true;
            }

            // Lấy dữ liệu từ session
            Username = HttpContext.Session.GetString("username");
            Email = HttpContext.Session.GetString("email");
            Role = HttpContext.Session.GetString("role");
        }
    }
}
