using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace DuAnBai3.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class InstrumentRentalsApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public InstrumentRentalsApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // 🟢 Lấy toàn bộ đơn thuê nhạc cụ
        [HttpGet]
        public IActionResult GetAll()
        {
            var rentals = _context.InstrumentRentals.ToList();
            return Ok(rentals);
        }

        // 🟢 Lấy đơn thuê theo ID
        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            var rental = _context.InstrumentRentals.FirstOrDefault(r => r.Id == id);
            if (rental == null) return NotFound();
            return Ok(rental);
        }

        // 🟢 Thêm mới đơn thuê
        [HttpPost]
        public IActionResult Create([FromBody] InstrumentRentals rental)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            rental.CreatedAt = DateTime.Now;
            _context.InstrumentRentals.Add(rental);
            _context.SaveChanges();

            return CreatedAtAction(nameof(GetById), new { id = rental.Id }, new
            {
                success = true,
                rentalId = rental.Id,
                message = "Tạo đơn thuê thành công"
            });
        }

        // 🟢 Cập nhật trạng thái
        [HttpPut("{id}")]
        public IActionResult UpdateStatus(int id, [FromBody] InstrumentRentals updated)
        {
            var rental = _context.InstrumentRentals.FirstOrDefault(r => r.Id == id);
            if (rental == null) return NotFound();

            rental.Status = updated.Status;
            _context.SaveChanges();
            return Ok(new { success = true, message = "Cập nhật trạng thái thành công", rental });
        }

        // 🟢 Xóa đơn thuê
        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var rental = _context.InstrumentRentals.FirstOrDefault(r => r.Id == id);
            if (rental == null) return NotFound();

            _context.InstrumentRentals.Remove(rental);
            _context.SaveChanges();
            return NoContent();
        }

        // 🟢 Lấy danh sách ID nhạc cụ đã thuê trong ngày cụ thể
        [HttpGet("status")]
        public async Task<IActionResult> GetInstrumentStatus([FromQuery] DateTime? date)
        {
            // Nếu không truyền ngày -> mặc định lấy hôm nay
            var targetDate = date.HasValue ? date.Value.Date : DateTime.Now.Date;

            // ✅ Lấy danh sách tất cả sản phẩm (nhạc cụ)
            var products = await _context.Products.ToListAsync();

            // ✅ Lấy các đơn thuê có RentalDate trùng ngày (bỏ phần time)
            var rentals = await _context.InstrumentRentals
                .Where(r => r.RentalDate.HasValue && r.RentalDate.Value.Date == targetDate)
                .ToListAsync();

            // ✅ Thu thập danh sách ID nhạc cụ đang được thuê
            var rentedIds = new List<int>();

            foreach (var rental in rentals)
            {
                if (string.IsNullOrWhiteSpace(rental.SelectedInstruments))
                    continue;

                try
                {
                    // Xử lý chuỗi JSON: có thể "[4,5]" hoặc "[25]"
                    var ids = JsonSerializer.Deserialize<List<int>>(rental.SelectedInstruments);
                    if (ids != null && ids.Any())
                        rentedIds.AddRange(ids);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Lỗi parse SelectedInstruments: {ex.Message}");
                }
            }

            // Loại trùng
            rentedIds = rentedIds.Distinct().ToList();

            // ✅ Chuẩn bị dữ liệu trả về cho Flutter
            var result = products.Select(p => new
            {
                id = p.Id,
                name = p.Name,
                price = p.Price,
                description = p.Description,
                imageUrl = p.ImageUrl, // ✅ Đúng key Flutter
                categoryId = p.CategoryId,
                isUnderMaintenance = p.IsUnderMaintenance,
                isRented = rentedIds.Contains(p.Id) // ✅ Đúng key Flutter
            });

            return Ok(result);
        }


    }
}
