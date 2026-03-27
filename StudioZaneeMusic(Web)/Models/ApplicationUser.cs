using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace DuAnBai3.Models
{
    public class ApplicationUser : IdentityUser
    {
        [Required]
        public string FullName { get; set; } = string.Empty;
        public string? Address { get; set; }
        public string? Age { get; set; }
        public string? Avatar { get; set; } = "/images/avatars/default-avatar.svg";

        // Thêm trường để quản lý session duy nhất
        public string? CurrentSessionId { get; set; }
        public DateTime? LastLoginTime { get; set; }
    }
}
