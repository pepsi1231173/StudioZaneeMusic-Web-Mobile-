using System.ComponentModel.DataAnnotations;

namespace DuAnBai3.Models
{
    public class Product
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Tên sản phẩm là bắt buộc")]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Range(1000, 1000000000, ErrorMessage = "Giá phải lớn hơn 1000đ")]
        public decimal Price { get; set; }

        // ✅ Cho phép NULL trong DB
        public string? Description { get; set; }

        // ✅ Cho phép NULL trong DB
        public string? ImageUrl { get; set; }

        // ✅ Bỏ Required, vì DB cho phép null
        [Display(Name = "Danh mục")]
        public int? CategoryId { get; set; }

        public Category? Category { get; set; }

        // ✅ Có giá trị mặc định (false)
        public bool IsUnderMaintenance { get; set; } = false;

        public bool IsRented { get; set; } = false;
    }
}
