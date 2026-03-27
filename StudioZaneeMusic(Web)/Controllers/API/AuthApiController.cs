using DuAnBai3.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;
using Google.Apis.Auth;

namespace DuAnBai3.Controllers.Api
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthApiController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly ILogger<AuthApiController> _logger;

        public AuthApiController(
            UserManager<ApplicationUser> userManager,
            SignInManager<ApplicationUser> signInManager,
            ILogger<AuthApiController> logger)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _logger = logger;
        }

        // ✅ POST: api/AuthApi/register
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest model)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ" });

            if (await _userManager.FindByEmailAsync(model.Email) != null)
                return BadRequest(new { success = false, message = "Email đã được sử dụng." });

            var user = new ApplicationUser
            {
                FullName = model.FullName,
                Email = model.Email,
                UserName = model.Email,
                PhoneNumber = model.PhoneNumber,
                Avatar = "/images/avatars/default-avatar.svg"
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
                return BadRequest(new { success = false, errors = result.Errors.Select(e => e.Description) });

            _logger.LogInformation($"Người dùng {user.Email} đã đăng ký thành công.");

            return Ok(new
            {
                success = true,
                message = "Đăng ký thành công!",
                user = new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    phoneNumber = user.PhoneNumber,
                    avatar = user.Avatar
                }
            });
        }

        // ✅ POST: api/AuthApi/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest model)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ" });

            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
                return Unauthorized(new { success = false, message = "Email hoặc mật khẩu không đúng." });

            var result = await _signInManager.PasswordSignInAsync(user.UserName, model.Password, false, false);
            if (!result.Succeeded)
                return Unauthorized(new { success = false, message = "Email hoặc mật khẩu không đúng." });

            return Ok(new
            {
                success = true,
                message = "Đăng nhập thành công!",
                user = new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    phoneNumber = user.PhoneNumber,
                    avatar = string.IsNullOrEmpty(user.Avatar)
                        ? "/images/avatars/default-avatar.svg"
                        : user.Avatar
                }
            });
        }

        // ✅ POST: api/AuthApi/LoginWithGoogle
        [HttpPost("LoginWithGoogle")]
        public async Task<IActionResult> LoginWithGoogle([FromBody] GoogleLoginRequest model)
        {
            try
            {
                var payload = await GoogleJsonWebSignature.ValidateAsync(model.IdToken, new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = new[]
                    {
                        "733911398737-5lp5cj8u69t5sogse349mh3equn0i6ef.apps.googleusercontent.com", // Web client ID
                        "733911398737-gi8pn33bh5dl3c4m6h5bu3gkr85t9t2m.apps.googleusercontent.com",// Android client ID
                        "385255830003-m709153qht2h2vjpoatmhsc3ln07eg9n.apps.googleusercontent.com",

                        "385255830003-rm4pavisto2d69043s9fv0fbp2bi0pd8.apps.googleusercontent.com"
                    }
                });

                var user = await _userManager.FindByEmailAsync(payload.Email);

                // ✅ Nếu user chưa tồn tại -> tạo mới
                if (user == null)
                {
                    user = new ApplicationUser
                    {
                        FullName = payload.Name,
                        Email = payload.Email,
                        UserName = payload.Email,
                        Avatar = payload.Picture ?? "/images/avatars/default-avatar.svg",
                        PhoneNumber = "" // ✅ Có thể cập nhật sau trên app
                    };

                    var result = await _userManager.CreateAsync(user);
                    if (!result.Succeeded)
                        return BadRequest(new { success = false, message = "Không thể tạo tài khoản Google." });
                }

                await _signInManager.SignInAsync(user, isPersistent: false);

                return Ok(new
                {
                    success = true,
                    message = "Đăng nhập Google thành công!",
                    user = new
                    {
                        id = user.Id,
                        fullName = user.FullName,
                        email = user.Email,
                        phoneNumber = user.PhoneNumber ?? "", // ✅ Thêm phone vào phản hồi
                        avatar = user.Avatar
                    }
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = $"Google login failed: {ex.Message}" });
            }
        }

        public class GoogleLoginRequest
        {
            public string IdToken { get; set; } = string.Empty;
        }
    }

    // ✅ Models
    public class RegisterRequest
    {
        [Required]
        public string FullName { get; set; }

        [Required, EmailAddress]
        public string Email { get; set; }

        [Required, Phone]
        public string PhoneNumber { get; set; }

        [Required, StringLength(100, MinimumLength = 6)]
        public string Password { get; set; }
    }

    public class LoginRequest
    {
        [Required, EmailAddress]
        public string Email { get; set; }

        [Required]
        public string Password { get; set; }
    }
}
