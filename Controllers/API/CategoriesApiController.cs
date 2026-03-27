using DuAnBai3.Models;
using DuAnBai3.Repositories;
using Microsoft.AspNetCore.Mvc;
using System.Linq;
using System.Threading.Tasks;

namespace DuAnBai3.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoriesApiController : ControllerBase
    {
        private readonly ICategoryRepository _categoryRepository;

        public CategoriesApiController(ICategoryRepository categoryRepository)
        {
            _categoryRepository = categoryRepository;
        }

        // Lấy tất cả danh mục
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var categories = await _categoryRepository.GetAllAsync();
            var result = categories.Select(c => new
            {
                c.Id,
                c.Name
            }).ToList();

            return Ok(result);
        }

        // Lấy danh mục theo id
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var category = await _categoryRepository.GetByIdAsync(id);
            if (category == null)
                return NotFound();

            return Ok(category);
        }

        // Thêm danh mục
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Category category)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            await _categoryRepository.AddAsync(category);
            return CreatedAtAction(nameof(GetById), new { id = category.Id }, category);
        }

        // Cập nhật danh mục
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Category category)
        {
            if (id != category.Id)
                return BadRequest("Mismatched ID");

            await _categoryRepository.UpdateAsync(category);
            return NoContent();
        }

        // Xóa danh mục
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var category = await _categoryRepository.GetByIdAsync(id);
            if (category == null)
                return NotFound();

            await _categoryRepository.DeleteAsync(id);
            return NoContent();
        }
    }
}
