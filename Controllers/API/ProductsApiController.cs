using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace DuAnBai3.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ProductsApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ GET: api/products
        // Lấy toàn bộ sản phẩm (có kèm tên danh mục)
        [HttpGet]
        public IActionResult GetAll()
        {
            var products = _context.Products
                .Include(p => p.Category)
                .Select(p => new
                {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.Description,
                    p.ImageUrl,
                    p.IsUnderMaintenance,
                    p.IsRented,
                    p.CategoryId, // ✅ thêm dòng này
                    CategoryName = p.Category.Name
                })
                .ToList();

            return Ok(products);
        }

        // ✅ GET: api/products/5
        // Lấy 1 sản phẩm cụ thể theo Id
        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            var product = _context.Products
                .Include(p => p.Category)
                .Where(p => p.Id == id)
                .Select(p => new
                {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.Description,
                    p.ImageUrl,
                    p.IsUnderMaintenance,
                    p.IsRented,
                    p.CategoryId, // ✅ thêm dòng này
                    CategoryName = p.Category.Name
                })
                .FirstOrDefault();

            if (product == null)
                return NotFound(new { message = "Không tìm thấy sản phẩm." });

            return Ok(product);
        }

        // ✅ GET: api/products/by-category/{categoryId}
        // Lấy danh sách sản phẩm theo loại nhạc cụ
        // ✅ GET: api/products/by-category/{categoryId}
        [HttpGet("by-category/{categoryId}")]
        public IActionResult GetByCategory(int categoryId)
        {
            var products = _context.Products
                .Include(p => p.Category)
                .Where(p => p.CategoryId == categoryId)
                .Select(p => new
                {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.Description,
                    p.ImageUrl,
                    p.IsUnderMaintenance,
                    p.IsRented,
                    p.CategoryId, // ✅ thêm dòng này
                    CategoryName = p.Category.Name
                })
                .ToList();

            // ❌ Không nên trả NotFound
            // ✅ Nên trả mảng rỗng
            return Ok(products);
        }

        // ✅ GET: api/products/by-name/{keyword}
        [HttpGet("by-name/{keyword}")]
        public IActionResult GetByName(string keyword)
        {
            if (string.IsNullOrWhiteSpace(keyword))
                return BadRequest(new { message = "Từ khóa không hợp lệ." });

            var normalizedKeyword = keyword.Trim().ToLower();

            var products = _context.Products
                .Include(p => p.Category)
                .AsEnumerable()
                .Where(p =>
                {
                    string name = RemoveDiacritics(p.Name.ToLower());
                    string category = RemoveDiacritics(p.Category.Name.ToLower());
                    string search = RemoveDiacritics(normalizedKeyword);
                    return name.Contains(search) || category.Contains(search);
                })
                .Select(p => new
                {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.Description,
                    p.ImageUrl,
                    p.IsUnderMaintenance,
                    p.IsRented,
                    p.CategoryId, // ✅ thêm dòng này
                    CategoryName = p.Category.Name
                })
                .ToList();

            // ✅ Luôn trả Ok([]) thay vì NotFound
            return Ok(products);
        }


        // ✅ Hàm bỏ dấu tiếng Việt (đặt trong cùng class)
        private static string RemoveDiacritics(string text)
        {
            if (string.IsNullOrEmpty(text))
                return text;

            var normalized = text.Normalize(System.Text.NormalizationForm.FormD);
            var sb = new System.Text.StringBuilder();

            foreach (var c in normalized)
            {
                var unicodeCategory = System.Globalization.CharUnicodeInfo.GetUnicodeCategory(c);
                if (unicodeCategory != System.Globalization.UnicodeCategory.NonSpacingMark)
                {
                    sb.Append(c);
                }
            }

            return sb.ToString().Normalize(System.Text.NormalizationForm.FormC);
        }


    }
}
