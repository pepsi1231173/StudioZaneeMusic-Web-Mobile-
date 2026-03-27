using DuAnBai3.Models;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using DuAnBai3.Hubs;


namespace DuAnBai3.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class InstrumentController : Controller
    {
        private readonly ApplicationDbContext _context;

        private readonly IHubContext<InstrumentHub> _hubContext;

        public InstrumentController(ApplicationDbContext context, IHubContext<InstrumentHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        public IActionResult Index()
        {
            var rentals = _context.InstrumentRentals
                .OrderByDescending(r => r.RentalDate)
                .ToList();

            var allProducts = _context.Products.ToList();
            ViewBag.AllProducts = allProducts;

            // Lấy danh sách nhạc cụ đang có đơn Pending hoặc Confirmed
            var rentedInstrumentIds = rentals
                .Where(r => r.Status == "Pending" || r.Status == "Confirmed")
                .SelectMany(r => JsonSerializer.Deserialize<List<int>>(r.SelectedInstruments ?? "[]"))
                .Distinct()
                .ToList();

            ViewBag.RentedInstrumentIds = rentedInstrumentIds;

            var model = rentals.Select(r => new InstrumentRentalViewModel
            {
                Rental = r,
                InstrumentNames = string.IsNullOrEmpty(r.SelectedInstruments)
                    ? new List<string>()
                    : JsonSerializer.Deserialize<List<int>>(r.SelectedInstruments)
                        .Select(id => allProducts.FirstOrDefault(p => p.Id == id)?.Name ?? "Không rõ")
                        .ToList(),
                InstrumentImages = string.IsNullOrEmpty(r.SelectedInstruments)
                    ? new List<string>()
                    : JsonSerializer.Deserialize<List<int>>(r.SelectedInstruments)
                        .Select(id => allProducts.FirstOrDefault(p => p.Id == id)?.ImageUrl ?? "/images/default.png")
                        .ToList()
            }).ToList();

            return View(model);
        }


        [HttpPost]
        public async Task<IActionResult> Confirm(int rentalId)
        {
            var rental = await _context.InstrumentRentals.FindAsync(rentalId);
            if (rental != null)
            {
                rental.Status = "Confirmed";
                _context.Update(rental);
                await _context.SaveChangesAsync();

                // ✅ Gửi SignalR thông báo realtime
                await _hubContext.Clients.All.SendAsync("RentalStatusChanged", rentalId, "Confirmed");
            }
            return RedirectToAction("Index");
        }

        [HttpPost]
        public async Task<IActionResult> Cancel(int rentalId)
        {
            var rental = await _context.InstrumentRentals.FindAsync(rentalId);
            if (rental != null)
            {
                rental.Status = "Cancelled";
                _context.Update(rental);
                await _context.SaveChangesAsync();

                // ✅ Gửi SignalR thông báo realtime
                await _hubContext.Clients.All.SendAsync("RentalStatusChanged", rentalId, "Cancelled");
            }
            return RedirectToAction("Index");
        }


        [HttpPost]
        public async Task<IActionResult> Delete(int rentalId)
        {
            var rental = await _context.InstrumentRentals.FindAsync(rentalId);
            if (rental != null)
            {
                _context.InstrumentRentals.Remove(rental);
                await _context.SaveChangesAsync();
            }
            return RedirectToAction("Index");
        }

        [HttpPost]
        public IActionResult CreateMaintenance(int[] ProductIds)
        {
            var allProducts = _context.Products.ToList();
            foreach (var p in allProducts)
            {
                p.IsUnderMaintenance = ProductIds.Contains(p.Id);
            }

            _context.SaveChanges();

            // ✅ Gửi SignalR danh sách nhạc cụ đang bảo trì
            var ids = allProducts.Where(p => p.IsUnderMaintenance).Select(p => p.Id).ToList();
            _hubContext.Clients.All.SendAsync("InstrumentMaintenanceUpdated", ids);

            return RedirectToAction("Index");
        }
    }

    public class InstrumentRentalViewModel
    {
        public InstrumentRentals Rental { get; set; }
        public List<string> InstrumentNames { get; set; }
        public List<string> InstrumentImages { get; set; }
    }
}
