using Microsoft.AspNetCore.Mvc;
using DuAnBai3.Models;
using System;
using System.Linq;

namespace DuAnBai3.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecordingInvoiceApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public RecordingInvoiceApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ GET: api/RecordingInvoiceApi
        // → Lấy danh sách tất cả hóa đơn thu âm
        [HttpGet]
        public IActionResult GetAllInvoices()
        {
            // Lấy dữ liệu từ database trước, chỉ các trường cần thiết
            var bookings = _context.RecordingBookings
                .Select(r => new
                {
                    r.Id,
                    r.CustomerName,
                    r.CustomerPhone,
                    r.CustomerEmail,
                    r.RecordingPackage,
                    r.RecordingDate,
                    r.RecordingTime,
                    r.Duration,
                    r.Price,
                    r.Status,
                    r.CreatedAt
                })
                .AsEnumerable() // Chuyển sang LINQ to Objects để xử lý format
                .Select(r => new
                {
                    MaDon = $"#{r.Id:D4}",
                    TenKhachHang = r.CustomerName,
                    SoDienThoai = r.CustomerPhone,
                    Email = r.CustomerEmail,
                    GoiDichVu = r.RecordingPackage,
                    NgayThuAm = r.RecordingDate.ToString("dd/MM/yyyy"),
                    GioThuAm = $"{r.RecordingTime:hh\\:mm} - {(r.RecordingTime + TimeSpan.FromHours(r.Duration)):hh\\:mm}",
                    Gia = $"{r.Price:N0} VNĐ",
                    TrangThai = r.Status,
                    NgayTao = r.CreatedAt.ToString("dd/MM/yyyy HH:mm"),
                    TongTien = $"{r.Price:N0} VNĐ"
                })
                .OrderByDescending(r => r.MaDon)
                .ToList();

            return Ok(bookings);
        }


        // ✅ GET: api/RecordingInvoiceApi/{recordingId}
        // → Lấy chi tiết hóa đơn thu âm theo ID
        [HttpGet("{recordingId}")]
        public IActionResult GetRecordingInvoice(int recordingId)
        {
            var record = _context.RecordingBookings.FirstOrDefault(r => r.Id == recordingId);
            if (record == null)
                return NotFound(new { message = "Không tìm thấy hóa đơn thu âm này." });

            var invoice = new
            {
                MaDon = $"#{record.Id:D4}",
                TenKhachHang = record.CustomerName,
                SoDienThoai = record.CustomerPhone,
                Email = record.CustomerEmail,
                GoiDichVu = record.RecordingPackage,
                NgayThuAm = record.RecordingDate.ToString("dd/MM/yyyy"),
                GioThuAm = $"{record.RecordingTime:hh\\:mm} - {(record.RecordingTime + TimeSpan.FromHours(record.Duration)):hh\\:mm}",
                Gia = $"{record.Price:N0} VNĐ",
                TrangThai = record.Status,
                NgayTao = record.CreatedAt.ToString("dd/MM/yyyy HH:mm"),
                TongTien = $"{record.Price:N0} VNĐ"
            };

            return Ok(invoice);
        }
    }
}
