using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using DuAnBai3.Hubs;
using DuAnBai3.Models;
using DuAnBai3.Services;
using System.Threading.Tasks;
using System.Linq;
using System.Collections.Generic;
using System;

namespace DuAnBai3.Areas.Admin.Controllers
{
    [Area("Admin")]
    [AutoValidateAntiforgeryToken]
    public class BookingController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<BookingHub> _hub;
        private readonly MaintenanceService _maintenance;

        public BookingController(
            ApplicationDbContext context,
            IHubContext<BookingHub> hub,
            MaintenanceService maintenanceService)
        {
            _context = context;
            _hub = hub;
            _maintenance = maintenanceService;
        }

        [HttpGet]
        public IActionResult Room()
        {
            var grouped = _context.Bookings
                .OrderBy(b => b.RentalDate)
                .ThenBy(b => b.StartTime)
                .AsEnumerable()
                .GroupBy(b => b.RentalDate.Date)
                .OrderBy(g => g.Key)
                .ToList();

            return View(grouped);
        }

        [HttpPost]
        public async Task<IActionResult> Approve([FromBody] DailyBookingDto dto)
        {
            if (dto == null || dto.DailyNumber <= 0) return BadRequest();

            var booking = await _context.Bookings
                .FirstOrDefaultAsync(b => b.RentalDate.Date == dto.RentalDate.Date
                                       && b.DailyBookingNumber == dto.DailyNumber);

            if (booking == null) return NotFound();
            if (booking.Status != "pending") return BadRequest("Đơn đã xử lý");

            var now = DateTime.Now;
            var startUtc = booking.RentalDate.Date + booking.StartTime;

            booking.Status = now >= startUtc ? "active" : "booked";
            booking.UpdatedAt = now;

            await _context.SaveChangesAsync();

            await _hub.Clients.All.SendAsync("BookingStatusChanged",
                booking.Id,
                booking.RoomId,
                booking.RentalDate.ToString("yyyy-MM-dd"),
                booking.StartTime.Hours,
                booking.RentalDuration,
                booking.Status);

            return Ok(new { status = booking.Status });
        }

        [HttpPost]
        public async Task<IActionResult> Cancel([FromBody] DailyBookingDto dto)
        {
            if (dto == null || dto.DailyNumber <= 0) return BadRequest();

            var booking = await _context.Bookings
                .FirstOrDefaultAsync(b => b.RentalDate.Date == dto.RentalDate.Date
                                       && b.DailyBookingNumber == dto.DailyNumber);

            if (booking == null) return NotFound();

            booking.Status = "cancelled";
            booking.UpdatedAt = DateTime.Now;
            await _context.SaveChangesAsync();

            await _hub.Clients.All.SendAsync("BookingStatusChanged",
                booking.Id,
                booking.RoomId,
                booking.RentalDate.ToString("yyyy-MM-dd"),
                booking.StartTime.Hours,
                booking.RentalDuration,
                "cancelled");

            return Ok();
        }


        [HttpPost]
        public async Task<IActionResult> Delete([FromBody] DailyBookingDto dto)
        {
            if (dto == null || dto.DailyNumber <= 0) return BadRequest();

            var booking = await _context.Bookings
                .FirstOrDefaultAsync(b => b.RentalDate.Date == dto.RentalDate.Date
                                       && b.DailyBookingNumber == dto.DailyNumber);

            if (booking == null) return NotFound();

            _context.Bookings.Remove(booking);
            await _context.SaveChangesAsync();

            // Gửi event riêng cho xóa
            await _hub.Clients.All.SendAsync(
        "BookingDeleted",
        booking.Id,
        booking.RoomId,
        booking.RentalDate.ToString("yyyy-MM-dd"),
        booking.StartTime.Hours,
        booking.RentalDuration
    );
                
            return Ok();
        }


        [HttpGet]
        public IActionResult History(int? page = 1, bool includeArchived = false)
        {
            const int PageSize = 20;
            int currentPage = page ?? 1;

            var query = _context.Bookings
                .Where(b => b.Status == "completed" || b.Status == "passed");

            if (!includeArchived)
            {
                query = query.Where(b => !b.IsArchived);
            }

            var allDone = query.OrderByDescending(b => b.RentalDate)
                               .ThenByDescending(b => b.StartTime);

            var paged = allDone.Skip((currentPage - 1) * PageSize)
                               .Take(PageSize)
                               .ToList();

            ViewBag.CurrentPage = currentPage;
            ViewBag.TotalPages = (int)Math.Ceiling(allDone.Count() / (double)PageSize);
            ViewBag.IncludeArchived = includeArchived;

            return View(paged);
        }


        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Archive(int id)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null) return NotFound();

            booking.IsArchived = true;
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(History));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Restore(int id)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null) return NotFound();

            booking.IsArchived = false;
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(History));
        }


        public class MaintenanceRequest
        {
            public List<string> Rooms { get; set; }
        }

        [HttpPost]
        public async Task<IActionResult> Maintenance([FromBody] MaintenanceRequest req)
        {
            var today = DateTime.Today;

            if (req == null || req.Rooms == null || !req.Rooms.Any())
            {
                // Nếu không có phòng nào được chọn => Xóa hết bảo trì
                _maintenance.ClearMaintenance();  // Bạn cần implement hàm này trong service
                var currentRooms = _maintenance.GetMaintenanceRooms();

                await _hub.Clients.All.SendAsync("MaintenanceUpdated", currentRooms);

                return Ok(currentRooms);
            }

            // Kiểm tra xem có phòng nào đang được đặt không
            var conflict = await _context.Bookings
                .Where(b =>
                    req.Rooms.Contains(b.RoomId) &&
                    b.RentalDate >= today &&
                    b.Status != "cancelled")
                .Select(b => b.RoomId)
                .Distinct()
                .ToListAsync();

            if (conflict.Any())
            {
                return BadRequest(new
                {
                    message = "Không thể bảo trì vì các phòng sau đang có khách đặt:",
                    rooms = conflict
                });
            }

            _maintenance.SetMaintenance(req.Rooms);
            var updatedRooms = _maintenance.GetMaintenanceRooms();

            await _hub.Clients.All.SendAsync("MaintenanceUpdated", updatedRooms);

            return Ok(updatedRooms);
        }

        [HttpGet]
        public IActionResult GetMaintenance()
        {
            var rooms = _maintenance.GetMaintenanceRooms(); // trả về List<string>
            return Ok(rooms);
        }

        [HttpPost]
        public async Task<IActionResult> CreateBooking([FromBody] Booking newBooking)
        {
            if (newBooking == null
                || string.IsNullOrEmpty(newBooking.RoomId)
                || newBooking.RentalDuration <= 0
                || newBooking.StartTime == default)
            {
                return BadRequest("Dữ liệu đặt phòng không hợp lệ");
            }

            var maxDailyNumber = await _context.Bookings
                .Where(b => b.RentalDate.Date == newBooking.RentalDate.Date)
                .MaxAsync(b => (int?)b.DailyBookingNumber) ?? 0;

            newBooking.DailyBookingNumber = maxDailyNumber + 1;
            newBooking.Status = "pending";
            newBooking.CreatedAt = DateTime.Now;

            _context.Bookings.Add(newBooking);
            await _context.SaveChangesAsync();

            await _hub.Clients.All.SendAsync("BookingCreated", new
            {
                id = newBooking.Id,
                dailyBookingNumber = newBooking.DailyBookingNumber,
                roomId = newBooking.RoomId,
                customerName = newBooking.CustomerName,
                rentalDate = newBooking.RentalDate.ToString("dd/MM/yyyy"),
                startTime = newBooking.StartTime.ToString(@"hh\:mm"),
                rentalDuration = newBooking.RentalDuration,
                price = newBooking.Price,
                status = newBooking.Status
            });

            return Ok(new { message = "Đặt phòng thành công", bookingId = newBooking.Id });
        }

    }

    public class DailyBookingDto
    {
        public DateTime RentalDate { get; set; }
        public int DailyNumber { get; set; }
    }
}
