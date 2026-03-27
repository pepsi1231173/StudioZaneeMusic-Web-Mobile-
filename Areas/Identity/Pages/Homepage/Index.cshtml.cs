using DuAnBai3.Models; // ApplicationUser
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace DuAnBai3.Areas.Identity.Pages
{
    public class HomepageModel : PageModel
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;

        public HomepageModel(UserManager<ApplicationUser> userManager,
                             SignInManager<ApplicationUser> signInManager)
        {
            _userManager = userManager;
            _signInManager = signInManager;
        }

        [BindProperty] public string FullName { get; set; }
        [BindProperty] public string Username { get; set; }
        [BindProperty] public string Email { get; set; }
        [BindProperty] public string PhoneNumber { get; set; }
        [BindProperty] public string CurrentPassword { get; set; }
        [BindProperty] public string NewPassword { get; set; }
        [BindProperty] public IFormFile AvatarFile { get; set; }
        public string Avatar { get; set; }

        public async Task OnGetAsync()
        {
            var user = await _userManager.GetUserAsync(User);
            if (user != null)
            {
                Username = user.UserName;
                Email = user.Email;
                PhoneNumber = user.PhoneNumber;
                Avatar = user.Avatar ?? "/images/avatars/default-avatar.svg"; // nếu có property Avatar trong ApplicationUser
                FullName = user.FullName ?? ""; // nếu có property FullName trong ApplicationUser
            }
        }

        public async Task<IActionResult> OnPostUpdateProfileAsync()
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null) return RedirectToPage("/Identity/Login");

            // Đổi mật khẩu
            if (!string.IsNullOrEmpty(CurrentPassword) && !string.IsNullOrEmpty(NewPassword))
            {
                var result = await _userManager.ChangePasswordAsync(user, CurrentPassword, NewPassword);
                if (!result.Succeeded)
                {
                    foreach (var error in result.Errors)
                        ModelState.AddModelError(string.Empty, error.Description);
                    return Page();
                }
            }

            // Cập nhật thông tin khác
            user.Email = Email;
            user.PhoneNumber = PhoneNumber;
            user.UserName = Username;

            // Cập nhật FullName và Avatar nếu bạn có thêm property
            if (AvatarFile != null)
            {
                var fileName = $"{Guid.NewGuid()}{Path.GetExtension(AvatarFile.FileName)}";
                var filePath = Path.Combine("wwwroot/images/avatars", fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await AvatarFile.CopyToAsync(stream);
                }

                user.Avatar = $"/images/avatars/{fileName}";
            }

            user.FullName = FullName;

            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
            {
                foreach (var error in updateResult.Errors)
                    ModelState.AddModelError(string.Empty, error.Description);
                return Page();
            }

            TempData["Success"] = "1";
            return Redirect("/Identity/Homepage");
        }
    }
}
