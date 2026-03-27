using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DuAnBai3.Models;

namespace DuAnBai3.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = SD.Role_Admin)]
    public class UserController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly ApplicationDbContext _context;

        public UserController(UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager, ApplicationDbContext context)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var users = await _userManager.Users.ToListAsync();
            var userViewModels = new List<UserViewModel>();

            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                userViewModels.Add(new UserViewModel
                {
                    Id = user.Id,
                    FullName = user.FullName,
                    Email = user.Email,
                    PhoneNumber = user.PhoneNumber,
                    Address = user.Address,
                    Age = user.Age,
                    Avatar = user.Avatar,
                    Roles = roles.ToList(),
                    IsLocked = await _userManager.IsLockedOutAsync(user)
                });
            }

            return View("~/Areas/Admin/Views/User/Index.cshtml", userViewModels);
        }

        public async Task<IActionResult> Details(string id)
        {
            if (string.IsNullOrEmpty(id)) return NotFound();
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound();

            var roles = await _userManager.GetRolesAsync(user);
            var userViewModel = new UserViewModel
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Address = user.Address,
                Age = user.Age,
                Avatar = user.Avatar,
                Roles = roles.ToList(),
                IsLocked = await _userManager.IsLockedOutAsync(user)
            };

            return View(userViewModel);
        }

        public async Task<IActionResult> ManageRoles(string userId)
        {
            if (string.IsNullOrEmpty(userId))
                return NotFound();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return NotFound();

            var userRoles = await _userManager.GetRolesAsync(user);
            var allRoles = await _roleManager.Roles.ToListAsync();

            var viewModel = new ManageUserRolesViewModel
            {
                UserId = user.Id,
                UserName = user.UserName ?? user.Email,
                UserRoles = allRoles.Select(role => new UserRoleViewModel
                {
                    RoleId = role.Id,
                    RoleName = role.Name ?? string.Empty,
                    IsSelected = userRoles.Contains(role.Name!)
                }).ToList()
            };

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> ManageRoles(ManageUserRolesViewModel model)
        {
            var user = await _userManager.FindByIdAsync(model.UserId);
            if (user == null)
                return NotFound();

            var currentRoles = await _userManager.GetRolesAsync(user);

            // Gỡ bỏ tất cả các quyền hiện có
            var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
            if (!removeResult.Succeeded)
            {
                ModelState.AddModelError("", "Không thể gỡ bỏ vai trò hiện tại của người dùng.");
                return View(model);
            }

            // Chọn các quyền mới được tích
            var selectedRoles = model.UserRoles
                .Where(r => r.IsSelected)
                .Select(r => r.RoleName)
                .ToList();

            var addResult = await _userManager.AddToRolesAsync(user, selectedRoles);
            if (!addResult.Succeeded)
            {
                ModelState.AddModelError("", "Không thể thêm vai trò mới cho người dùng.");
                return View(model);
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        public async Task<IActionResult> LockUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return Json(new { success = false, message = "Không tìm thấy user" });

            var result = await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.UtcNow.AddYears(100));
            return Json(new { success = result.Succeeded, message = result.Succeeded ? "Khóa tài khoản thành công" : "Không thể khóa tài khoản" });
        }

        [HttpPost]
        public async Task<IActionResult> UnlockUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return Json(new { success = false, message = "Không tìm thấy user" });

            var result = await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.UtcNow);
            if (result.Succeeded)
            {
                await _userManager.ResetAccessFailedCountAsync(user);
                return Json(new { success = true, message = "Mở khóa tài khoản thành công" });
            }

            return Json(new { success = false, message = "Không thể mở khóa tài khoản" });
        }

        [HttpPost]
        public async Task<IActionResult> ResetFailedAttempts(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return Json(new { success = false, message = "Không tìm thấy user" });

            var result = await _userManager.ResetAccessFailedCountAsync(user);
            return Json(new { success = result.Succeeded, message = result.Succeeded ? "Reset thành công" : "Không thể reset" });
        }

        public IActionResult CreateRole() => View();

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateRole(CreateRoleViewModel model)
        {
            if (!ModelState.IsValid) return View(model);

            if (await _roleManager.RoleExistsAsync(model.RoleName))
            {
                ModelState.AddModelError("", "Role này đã tồn tại");
                return View(model);
            }

            var result = await _roleManager.CreateAsync(new IdentityRole(model.RoleName));
            if (result.Succeeded)
            {
                TempData["success"] = "Tạo role thành công";
                return RedirectToAction("ManageRoles");
            }

            foreach (var error in result.Errors)
                ModelState.AddModelError("", error.Description);

            return View(model);
        }

        public async Task<IActionResult> RolesList()
        {
            var roles = await _roleManager.Roles.ToListAsync();
            return View(roles);
        }

        [HttpPost]
        public async Task<IActionResult> DeleteRole(string id)
        {
            var role = await _roleManager.FindByIdAsync(id);
            if (role == null) return Json(new { success = false, message = "Không tìm thấy role" });

            var usersInRole = await _userManager.GetUsersInRoleAsync(role.Name);
            if (usersInRole.Any()) return Json(new { success = false, message = "Không thể xóa role vì có user sử dụng" });

            var result = await _roleManager.DeleteAsync(role);
            return Json(new { success = result.Succeeded, message = result.Succeeded ? "Xóa role thành công" : "Không thể xóa role" });
        }

        [HttpPost]
        public async Task<IActionResult> ResetAvatar(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return Json(new { success = false, message = "ID không hợp lệ" });

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) return Json(new { success = false, message = "Không tìm thấy người dùng" });

            if (!string.IsNullOrEmpty(user.Avatar) && !user.Avatar.Contains("default-avatar"))
            {
                var path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", user.Avatar.TrimStart('/'));
                if (System.IO.File.Exists(path)) System.IO.File.Delete(path);
            }

            user.Avatar = "/images/avatars/default-avatar.svg";
            var result = await _userManager.UpdateAsync(user);
            return Json(new { success = result.Succeeded, message = result.Succeeded ? "Reset avatar thành công" : "Không thể reset avatar" });
        }

        [HttpPost]
        public async Task<IActionResult> UploadAvatar(string userId, IFormFile avatarFile)
        {
            if (string.IsNullOrEmpty(userId)) return Json(new { success = false, message = "User ID không hợp lệ" });
            if (avatarFile == null || avatarFile.Length == 0) return Json(new { success = false, message = "Vui lòng chọn file ảnh" });

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) return Json(new { success = false, message = "Không tìm thấy user" });

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif" };
            var extension = Path.GetExtension(avatarFile.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(extension)) return Json(new { success = false, message = "Định dạng ảnh không hợp lệ" });
            if (avatarFile.Length > 5 * 1024 * 1024) return Json(new { success = false, message = "Ảnh vượt quá 5MB" });

            var folder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "avatars");
            if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);

            if (!string.IsNullOrEmpty(user.Avatar) && !user.Avatar.Contains("default-avatar"))
            {
                var oldPath = Path.Combine("wwwroot", user.Avatar.TrimStart('/'));
                if (System.IO.File.Exists(oldPath)) System.IO.File.Delete(oldPath);
            }

            var fileName = $"{user.Id}_{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(folder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await avatarFile.CopyToAsync(stream);
            }

            user.Avatar = $"/images/avatars/{fileName}";
            var updateResult = await _userManager.UpdateAsync(user);

            if (updateResult.Succeeded)
            {
                return Json(new { success = true, message = "Upload avatar thành công", avatarPath = user.Avatar });
            }
            else
            {
                if (System.IO.File.Exists(filePath)) System.IO.File.Delete(filePath);
                return Json(new { success = false, message = "Không thể cập nhật avatar" });
            }
        }
    }
}