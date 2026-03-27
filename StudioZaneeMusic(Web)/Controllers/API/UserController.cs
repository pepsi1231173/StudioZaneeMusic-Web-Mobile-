using DuAnBai3.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace DuAnBai3.Controllers.Api
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IWebHostEnvironment _env;
        private readonly ILogger<UserController> _logger;

        public UserController(UserManager<ApplicationUser> userManager, IWebHostEnvironment env, ILogger<UserController> logger)
        {
            _userManager = userManager;
            _env = env;
            _logger = logger;
        }

        // ✅ Cập nhật thông tin người dùng
        [HttpPost("update/{id}")]
        public async Task<IActionResult> UpdateUser(string id, [FromForm] UpdateUserRequest model)
        {
            if (string.IsNullOrEmpty(id))
                return BadRequest(new { success = false, message = "Thiếu ID người dùng" });

            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { success = false, message = "Người dùng không tồn tại" });

            try
            {
                // ✅ Đổi mật khẩu nếu có
                if (!string.IsNullOrEmpty(model.CurrentPassword) && !string.IsNullOrEmpty(model.NewPassword))
                {
                    var passwordHasher = new PasswordHasher<ApplicationUser>();
                    var verifyResult = passwordHasher.VerifyHashedPassword(user, user.PasswordHash, model.CurrentPassword);

                    if (verifyResult == PasswordVerificationResult.Failed)
                        return BadRequest(new { success = false, message = "Mật khẩu hiện tại không đúng" });

                    user.PasswordHash = passwordHasher.HashPassword(user, model.NewPassword);
                }

                // ✅ Cập nhật thông tin
                user.FullName = model.FullName ?? user.FullName;
                user.UserName = model.Username ?? user.UserName;
                user.Email = model.Email ?? user.Email;
                user.PhoneNumber = model.PhoneNumber ?? user.PhoneNumber;

                // ✅ Upload avatar mới
                if (model.AvatarFile != null && model.AvatarFile.Length > 0)
                {
                    string folderPath = Path.Combine(_env.WebRootPath, "images/avatars");
                    if (!Directory.Exists(folderPath))
                        Directory.CreateDirectory(folderPath);

                    // Xóa ảnh cũ
                    if (!string.IsNullOrEmpty(user.Avatar) && !user.Avatar.Contains("default-avatar"))
                    {
                        string oldFilePath = Path.Combine(_env.WebRootPath, user.Avatar.TrimStart('/'));
                        if (System.IO.File.Exists(oldFilePath))
                            System.IO.File.Delete(oldFilePath);
                    }

                    string newFileName = $"{Guid.NewGuid()}{Path.GetExtension(model.AvatarFile.FileName)}";
                    string newFilePath = Path.Combine(folderPath, newFileName);

                    using (var stream = new FileStream(newFilePath, FileMode.Create))
                    {
                        await model.AvatarFile.CopyToAsync(stream);
                    }

                    user.Avatar = $"/images/avatars/{newFileName}";
                }

                var result = await _userManager.UpdateAsync(user);
                if (!result.Succeeded)
                    return BadRequest(new { success = false, message = "Cập nhật thất bại", errors = result.Errors.Select(e => e.Description) });

                return Ok(new
                {
                    success = true,
                    message = "Cập nhật thành công",
                    user = new
                    {
                        id = user.Id,
                        fullName = user.FullName,
                        username = user.UserName,
                        email = user.Email,
                        phoneNumber = user.PhoneNumber,
                        avatar = user.Avatar
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật người dùng");
                return StatusCode(500, new { success = false, message = "Lỗi server", error = ex.Message });
            }
        }

        // ✅ Lấy thông tin người dùng theo ID
        [HttpGet("{id}")]
        public async Task<IActionResult> GetUserById(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { success = false, message = "Không tìm thấy người dùng" });

            return Ok(new
            {
                success = true,
                user = new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    username = user.UserName,
                    email = user.Email,
                    phoneNumber = user.PhoneNumber,
                    avatar = user.Avatar
                }
            });
        }

        // ✅ Lấy danh sách người dùng
        [HttpGet("all")]
        public IActionResult GetAllUsers()
        {
            var users = _userManager.Users.Select(u => new
            {
                id = u.Id,
                fullName = u.FullName,
                username = u.UserName,
                email = u.Email,
                phoneNumber = u.PhoneNumber,
                avatar = u.Avatar
            }).ToList();

            return Ok(new { success = true, users });
        }
    }

    public class UpdateUserRequest
    {
        public string? FullName { get; set; }
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? CurrentPassword { get; set; }
        public string? NewPassword { get; set; }
        public IFormFile? AvatarFile { get; set; }
    }
}
