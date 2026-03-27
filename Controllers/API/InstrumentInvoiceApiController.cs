using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;

namespace DuAnBai3.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class InstrumentInvoiceApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public InstrumentInvoiceApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/InstrumentInvoiceApi
        // GET: api/InstrumentInvoiceApi
        [HttpGet]
        public IActionResult GetAllInvoices()
        {
            var products = _context.Products
                .Select(p => new { p.Id, p.Name, p.Price, p.ImageUrl })
                .ToList();

            var rentals = _context.InstrumentRentals
                .AsEnumerable()
                .Select(r =>
                {
                    var selectedIds = JsonConvert.DeserializeObject<List<int>>(r.SelectedInstruments ?? "[]");

                    // Lấy danh sách nhạc cụ chi tiết (Name, Price, ImageUrl)
                    var instruments = products
                        .Where(p => selectedIds.Contains(p.Id))
                        .Select(p => new
                        {
                            p.Id,
                            Name = p.Name,
                            Price = p.Price,
                            ImageUrl = p.ImageUrl
                        })
                        .ToList();

                    decimal total = instruments.Sum(i => i.Price);

                    return new
                    {
                        MaDon = $"#I{r.Id:D4}",
                        TenKhachHang = r.CustomerName,
                        SoDienThoai = r.CustomerPhone,
                        Email = r.CustomerEmail,
                        NgayThue = r.RentalDate?.ToString("dd/MM/yyyy"),
                        NgayTao = r.CreatedAt?.ToString("dd/MM/yyyy HH:mm"),
                        DanhSachNhacCu = instruments,
                        TongTien = $"{total:N0} VNĐ"
                    };
                })
                .OrderByDescending(x => x.MaDon)
                .ToList();

            return Ok(rentals);
        }


        // GET: api/InstrumentInvoiceApi/{rentalId}
        [HttpGet("{rentalId}")]
        public IActionResult GetInstrumentInvoice(int rentalId)
        {
            var rental = _context.InstrumentRentals.FirstOrDefault(r => r.Id == rentalId);
            if (rental == null)
                return NotFound(new { message = "Không tìm thấy hóa đơn thuê nhạc cụ này." });

            var instrumentIds = JsonConvert.DeserializeObject<List<int>>(rental.SelectedInstruments ?? "[]");
            var instruments = _context.Products
                .Where(p => instrumentIds.Contains(p.Id))
                .Select(p => new
                {
                    p.Name,
                    p.Price,
                    p.ImageUrl
                })
                .ToList();

            decimal total = instruments.Sum(i => i.Price);

            var invoice = new
            {
                MaDon = $"#I{rental.Id:D4}",
                TenKhachHang = rental.CustomerName,
                SoDienThoai = rental.CustomerPhone,
                Email = rental.CustomerEmail,
                NgayThue = rental.RentalDate?.ToString("dd/MM/yyyy"),
                NgayTao = rental.CreatedAt?.ToString("dd/MM/yyyy HH:mm"),
                DanhSachNhacCu = instruments,
                TongTien = $"{total:N0} VNĐ"
            };

            return Ok(invoice);
        }

        // POST: api/InstrumentInvoiceApi/create
        [HttpPost("create")]
        public IActionResult CreateRental([FromBody] CreateRentalRequest request)
        {
            if (request == null || request.SelectedInstruments == null || !request.SelectedInstruments.Any())
                return BadRequest(new { success = false, message = "Danh sách nhạc cụ không được để trống" });

            // Tính tổng tiền (giả sử Price là decimal)
            var totalPrice = _context.Products
                .Where(p => request.SelectedInstruments.Contains(p.Id))
                .Sum(p => p.Price);

            var rental = new InstrumentRentals
            {
                CustomerName = request.CustomerName,
                CustomerPhone = request.CustomerPhone,
                CustomerEmail = request.CustomerEmail,
                RentalDate = request.RentalDate,
                SelectedInstruments = JsonConvert.SerializeObject(request.SelectedInstruments),
                TotalPrice = (int)totalPrice,
                CreatedAt = DateTime.Now,
                Status = "Pending"
            };

            _context.InstrumentRentals.Add(rental);
            _context.SaveChanges();

            return Ok(new
            {
                success = true,
                rentalId = rental.Id,
                message = "Đặt thuê thành công"
            });
        }

        public class CreateRentalRequest
        {
            public string CustomerName { get; set; }
            public string CustomerPhone { get; set; }
            public string CustomerEmail { get; set; }
            public DateTime? RentalDate { get; set; }
            public List<int> SelectedInstruments { get; set; }
        }
    }
}