#nullable disable

using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging;
using DuAnBai3.Models;

namespace DuAnBai3.Areas.Identity.Pages.Account
{
    public class LoginModel : PageModel
    {
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ILogger<LoginModel> _logger;
        private readonly IHttpContextAccessor _httpContextAccessor;


        public LoginModel(
             SignInManager<ApplicationUser> signInManager,
             UserManager<ApplicationUser> userManager,
             ILogger<LoginModel> logger,
             IHttpContextAccessor httpContextAccessor)
        {
            _signInManager = signInManager;
            _userManager = userManager;
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;
        }
        [BindProperty]
        public InputModel Input { get; set; }

        public IList<AuthenticationScheme> ExternalLogins { get; set; }

        public string ReturnUrl { get; set; }

        [TempData]
        public string ErrorMessage { get; set; }

        public class InputModel
        {
            [Required]
            [EmailAddress]
            public string Email { get; set; }

            [Required]
            [DataType(DataType.Password)]
            public string Password { get; set; }

            [Display(Name = "Remember me?")]
            public bool RememberMe { get; set; }
        }

        public async Task OnGetAsync(string returnUrl = null)
        {
            if (!string.IsNullOrEmpty(ErrorMessage))
            {
                ModelState.AddModelError(string.Empty, ErrorMessage);
            }

            returnUrl ??= Url.Content("~/");

            // Clear external cookie
            await HttpContext.SignOutAsync(IdentityConstants.ExternalScheme);

            ExternalLogins = (await _signInManager.GetExternalAuthenticationSchemesAsync()).ToList();

            ReturnUrl = returnUrl;
        }

        public async Task<IActionResult> OnPostAsync(string returnUrl = null)
        {
            // Gán lại returnUrl nếu không hợp lệ
            if (string.IsNullOrEmpty(returnUrl) || returnUrl.Contains("/Identity/Home"))
            {
                returnUrl = "/";
            }

            ExternalLogins = (await _signInManager.GetExternalAuthenticationSchemesAsync()).ToList();

            if (ModelState.IsValid)
            {
                var user = await _userManager.FindByEmailAsync(Input.Email);
                if (user != null)
                {
                    var result = await _signInManager.PasswordSignInAsync(
                        user.UserName, Input.Password, Input.RememberMe, lockoutOnFailure: false);

                    if (result.Succeeded)
                    {
                        _logger.LogInformation("User logged in.");

                        var roleList = await _userManager.GetRolesAsync(user);
                        string role = "";
                        if (roleList.Contains("Admin"))
                            role = "Admin";
                        else if (roleList.Contains("Cashier"))
                            role = "Cashier";
                        else if (roleList.Contains("Customer"))
                            role = "Customer";
                        else
                            role = roleList.FirstOrDefault() ?? "";


                        _httpContextAccessor.HttpContext.Session.SetString("username", user.UserName);
                        _httpContextAccessor.HttpContext.Session.SetString("email", user.Email);
                        _httpContextAccessor.HttpContext.Session.SetString("role", role);

                        // ✅ Điều hướng rõ ràng theo vai trò
                        if (role == "Admin")
                            return RedirectToAction("Dashboard", "Homepage", new { area = "Admin" });

                        if (role == "Cashier")
                            return RedirectToAction("Index", "Dashboard", new { area = "Cashier" });

                        if (role == "Customer")
                            return RedirectToPage("/HomePage/Index", new { area = "Identity" });

                        return RedirectToAction("Index", "Dashboard", new { area = "Cashier" });// fallback
                    }

                    if (result.RequiresTwoFactor)
                    {
                        // ❗ KHÔNG truyền lại returnUrl
                        return RedirectToPage("./LoginWith2fa", new
                        {
                            RememberMe = Input.RememberMe
                        });
                    }

                    if (result.IsLockedOut)
                    {
                        _logger.LogWarning("User account locked out.");
                        return RedirectToPage("./Lockout");
                    }
                }

                ModelState.AddModelError(string.Empty, "Đăng nhập không hợp lệ.");
            }

            return Page();
        }

    }
}
