using DuAnBai3.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;
using System.Threading.Tasks;

namespace DuAnBai3.Pages.Account
{
    public class ForgotPasswordModel : PageModel
    {
        private readonly UserManager<ApplicationUser> _userManager;

        public ForgotPasswordModel(UserManager<ApplicationUser> userManager)
        {
            _userManager = userManager;
        }

        [BindProperty]
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; }

        [BindProperty]
        [Required(ErrorMessage = "Vui lòng nhập mật khẩu mới.")]
        [StringLength(100, MinimumLength = 6)]
        [DataType(DataType.Password)]
        public string NewPassword { get; set; }

        [BindProperty]
        public bool Step2 { get; set; } = false; // bước 2: nhập mật khẩu mới

        public string Message { get; set; }

        public void OnGet()
        {
            Step2 = false;
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid) return Page();

            if (!Step2)
            {
                // --- Bước 1: kiểm tra email ---
                var user = await _userManager.FindByEmailAsync(Email.Trim());
                if (user == null)
                {
                    Message = "Email không tồn tại!";
                    return Page();
                }

                // Email hợp lệ → chuyển sang bước nhập mật khẩu mới
                Step2 = true;
                ModelState.Clear(); // xóa validation cũ
                return Page();
            }
            else
            {
                // --- Bước 2: đặt mật khẩu mới ---
                var user = await _userManager.FindByEmailAsync(Email.Trim());
                if (user == null)
                {
                    Message = "Người dùng không tồn tại!";
                    Step2 = false;
                    return Page();
                }

                var token = await _userManager.GeneratePasswordResetTokenAsync(user);
                var result = await _userManager.ResetPasswordAsync(user, token, NewPassword);

                if (result.Succeeded)
                {
                    Message = "Đặt mật khẩu mới thành công!";
                    Step2 = false;
                    ModelState.Clear();
                }
                else
                {
                    Message = "Đặt mật khẩu thất bại: " + string.Join(", ", result.Errors);
                }

                return Page();
            }
        }
    }
}
