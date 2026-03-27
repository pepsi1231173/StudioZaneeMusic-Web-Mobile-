using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using DuAnBai3.Models;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace DuAnBai3.Areas.Identity.Pages.Instruments
{
    [Area("Identity")]
    public class ListModel : PageModel
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public ListModel(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        [BindProperty]
        public InstrumentInputModel Instrument { get; set; } = new InstrumentInputModel();

        public List<Category> Categories { get; set; } = new List<Category>();
        public Dictionary<string, List<InstrumentItem>> InstrumentsDict { get; set; } = new();

        public async Task OnGetAsync()
        {
            await LoadCategoriesAndInstrumentsAsync();
            // Điền thông tin user tự động
            var user = await _userManager.GetUserAsync(User);
            if (user != null)
            {
                Instrument.CustomerName = user.FullName ?? user.UserName;
                Instrument.CustomerEmail = user.Email ?? "";
                Instrument.CustomerPhone = user.PhoneNumber ?? "";
            }
        }

        public async Task<IActionResult> OnPostAsync()
        {
            await LoadCategoriesAndInstrumentsAsync();

            if (!ModelState.IsValid)
                return Page();

            if (Instrument.SelectedInstruments == null || !Instrument.SelectedInstruments.Any())
            {
                ModelState.AddModelError(nameof(Instrument.SelectedInstruments), "Vui lòng chọn ít nhất 1 nhạc cụ.");
                return Page();
            }

            // Tính tổng giá
            int totalPrice = 0;
            var selectedIds = Instrument.SelectedInstruments;
            foreach (var categoryItems in InstrumentsDict.Values)
            {
                foreach (var instrument in categoryItems)
                {
                    if (selectedIds.Contains(instrument.Id))
                        totalPrice += instrument.Price;
                }
            }
            Instrument.TotalPrice = totalPrice;

            // Tạo rental
            var rental = new Rental
            {
                CustomerName = Instrument.CustomerName,
                CustomerPhone = Instrument.CustomerPhone,
                CustomerEmail = Instrument.CustomerEmail,
                RentalDate = Instrument.RentalDate,
                CreatedAt = DateTime.Now,
                SelectedInstruments = selectedIds,
                TotalPrice = totalPrice,
                Status = "Pending"
            };

            int createdRentalId = await SaveRentalToDbAsync(rental);

            TempData["SuccessMessage"] = $"✅ Hóa đơn số {createdRentalId} đã được tạo thành công!";
            return RedirectToPage("/Instruments/Invoice", new { area = "Identity", rental_id = createdRentalId });
        }

        private async Task<int> SaveRentalToDbAsync(Rental rental)
        {
            const string connectionString = "Server=LAPTOP-KS75264J\\SQLEXPRESS;Database=ĐACS;Trusted_Connection=True;TrustServerCertificate=True";

            await using var conn = new SqlConnection(connectionString);
            await conn.OpenAsync();

            string insertSql = @"
                INSERT INTO InstrumentRentals 
                (CustomerName, CustomerPhone, CustomerEmail, RentalDate, CreatedAt, SelectedInstruments, TotalPrice, Status)
                OUTPUT INSERTED.Id
                VALUES (@CustomerName, @CustomerPhone, @CustomerEmail, @RentalDate, @CreatedAt, @SelectedInstruments, @TotalPrice, @Status);
            ";

            await using var cmd = new SqlCommand(insertSql, conn);
            cmd.Parameters.AddWithValue("@CustomerName", rental.CustomerName ?? "");
            cmd.Parameters.AddWithValue("@CustomerPhone", rental.CustomerPhone ?? "");
            cmd.Parameters.AddWithValue("@CustomerEmail", rental.CustomerEmail ?? "");
            cmd.Parameters.AddWithValue("@RentalDate", (object?)rental.RentalDate ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@CreatedAt", rental.CreatedAt);
            cmd.Parameters.AddWithValue("@SelectedInstruments", JsonSerializer.Serialize(rental.SelectedInstruments));
            cmd.Parameters.AddWithValue("@TotalPrice", rental.TotalPrice);
            cmd.Parameters.AddWithValue("@Status", rental.Status ?? "Pending");

            int insertedId = (int)await cmd.ExecuteScalarAsync();
            rental.Id = insertedId;
            return insertedId;
        }

        private async Task LoadCategoriesAndInstrumentsAsync()
        {
            Categories = await _context.Categories.AsNoTracking().OrderBy(c => c.Name).ToListAsync();
            var products = await _context.Products.AsNoTracking().OrderBy(p => p.Name).ToListAsync();

            var selectedDate = Instrument.RentalDate?.Date ?? DateTime.Now.Date;

            // Lấy tất cả rental đã Confirmed cho ngày chọn
            var confirmedRentals = await _context.InstrumentRentals
                .Where(r => r.RentalDate.HasValue && r.RentalDate.Value.Date == selectedDate
                            && r.Status == "Confirmed" || r.Status == "Pending") // Hoặc "Approved"
                .ToListAsync();

            var rentedIdsForDate = confirmedRentals
                .SelectMany(r => JsonSerializer.Deserialize<List<int>>(r.SelectedInstruments ?? "[]"))
                .ToList();

            InstrumentsDict.Clear();
            foreach (var category in Categories)
            {
                var items = products
                    .Where(p => p.CategoryId == category.Id)
                    .Select(p => new InstrumentItem
                    {
                        Id = p.Id,
                        Name = p.Name ?? "",
                        Price = (int)p.Price,
                        Img = string.IsNullOrEmpty(p.ImageUrl) ? "/images/products/default.jpg" : p.ImageUrl,
                        IsUnderMaintenance = p.IsUnderMaintenance,
                        IsRented = rentedIdsForDate.Contains(p.Id)
                    })
                    .ToList();

                InstrumentsDict[category.Name] = items;
            }
        }

        // Endpoint gọi khi chọn ngày
        public async Task<JsonResult> OnGetGetInstrumentsStatus(DateTime date)
        {
            // Lấy tất cả đơn thuê (Pending hoặc Confirmed) cho ngày được chọn
            var rentals = await _context.InstrumentRentals
                .Where(r => r.RentalDate.HasValue && r.RentalDate.Value.Date == date
                            && (r.Status == "Pending" || r.Status == "Confirmed"))
                .ToListAsync();

            // Lấy tất cả ID nhạc cụ đã thuê
            var rentedIds = rentals
                .SelectMany(r => JsonSerializer.Deserialize<List<int>>(r.SelectedInstruments ?? "[]"))
                .ToList();

            return new JsonResult(rentedIds);
        }



        // Các class model
        public class Rental
        {
            public int Id { get; set; }
            public string CustomerName { get; set; } = "";
            public string CustomerPhone { get; set; } = "";
            public string CustomerEmail { get; set; } = "";
            public DateTime? RentalDate { get; set; }
            public DateTime CreatedAt { get; set; } = DateTime.Now;
            public List<int> SelectedInstruments { get; set; } = new();
            public int TotalPrice { get; set; }
            public string Status { get; set; } = "Pending";
        }

        public class InstrumentItem
        {
            public int Id { get; set; }
            public string Name { get; set; } = "";
            public int Price { get; set; }
            public string Img { get; set; } = "";
            public bool IsUnderMaintenance { get; set; }
            public bool IsRented { get; set; }
        }

        public class InstrumentInputModel
        {
            [Required] public string CustomerName { get; set; } = "";
            [Required] public string CustomerPhone { get; set; } = "";
            [Required, EmailAddress] public string CustomerEmail { get; set; } = "";
            [Required, DataType(DataType.Date)] public DateTime? RentalDate { get; set; }
            [Required] public List<int> SelectedInstruments { get; set; } = new List<int>();
            public int TotalPrice { get; set; }
        }
    }
}
