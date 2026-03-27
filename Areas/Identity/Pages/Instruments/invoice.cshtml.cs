using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using System.Text.Json;

namespace DuAnBai3.Areas.Identity.Pages.Instruments
{
    [Area("Identity")]
    public class InvoiceModel : PageModel
    {
        private const string _cnn =
            "Server=LAPTOP-KS75264J\\SQLEXPRESS;Database=ĐACS;Trusted_Connection=True;TrustServerCertificate=True";

        [BindProperty(SupportsGet = true)]
        public int rental_id { get; set; }

        public RentalInfo Rental { get; private set; }
        public List<InstrumentItem> Instruments { get; private set; } = new();
        public int TotalPrice { get; private set; }

        // --------------------------------------------------------------
        public async Task<IActionResult> OnGetAsync(int rental_id)
        {
            if (rental_id <= 0) { Rental = null; return Page(); }

            await using var conn = new SqlConnection(_cnn);
            await conn.OpenAsync();

            // —— 1. Lấy bản ghi invoice
            var invoiceCmd = new SqlCommand(
                "SELECT * FROM InstrumentRentals WHERE Id=@Id", conn);
            invoiceCmd.Parameters.AddWithValue("@Id", rental_id);

            await using var rdr = await invoiceCmd.ExecuteReaderAsync();

            if (!await rdr.ReadAsync()) { Rental = null; return Page(); }

            // Map dữ liệu
            string raw = rdr["SelectedInstruments"]?.ToString() ?? "[]";
            List<int> ids;
            try { ids = JsonSerializer.Deserialize<List<int>>(raw) ?? new(); }
            catch { ids = raw.Split(',').Select(x => int.TryParse(x, out var id) ? id : 0).Where(x => x > 0).ToList(); }

            Rental = new RentalInfo
            {
                CustomerName = rdr["CustomerName"]?.ToString() ?? "",
                CustomerPhone = rdr["CustomerPhone"]?.ToString() ?? "",
                CustomerEmail = rdr["CustomerEmail"]?.ToString() ?? "",
                RentalDate = rdr["RentalDate"] as DateTime?,
                CreatedAt = rdr["CreatedAt"] as DateTime?,
                TotalPrice = rdr["TotalPrice"] is int t ? t : 0,
                SelectedInstruments = ids
            };
            await rdr.CloseAsync();

            // —— 2. Lấy chi tiết nhạc cụ
            if (ids.Any()) await LoadInstrumentDetailsAsync(conn, ids);

            // Nếu DB để TotalPrice=0, tự tính lại
            TotalPrice = Rental.TotalPrice > 0
                         ? Rental.TotalPrice
                         : Instruments.Sum(i => i.Price);

            return Page();
        }

        // --------------------------------------------------------------
        private async Task LoadInstrumentDetailsAsync(SqlConnection conn, List<int> ids)
        {
            var cmd = new SqlCommand { Connection = conn };
            var names = new List<string>();

            for (int i = 0; i < ids.Count; i++)
            {
                var pn = "@id" + i;
                cmd.Parameters.AddWithValue(pn, ids[i]);
                names.Add(pn);
            }

            cmd.CommandText =
                $"SELECT Id,Name,Price,ImageUrl FROM Products WHERE Id IN ({string.Join(',', names)})";

            await using var rdr = await cmd.ExecuteReaderAsync();
            Instruments.Clear();

            while (await rdr.ReadAsync())
            {
                Instruments.Add(new InstrumentItem
                {
                    Id = rdr.GetInt32(0),
                    Name = rdr.IsDBNull(1) ? "" : rdr.GetString(1),
                    Price = (int)rdr.GetDecimal(2),
                    ImageUrl = rdr.IsDBNull(3) ? "/images/default.jpg" : rdr.GetString(3)
                });
            }
        }


        // ==== DTO ============================================================
        public class RentalInfo
        {
            public string CustomerName { get; set; }
            public string CustomerPhone { get; set; }
            public string CustomerEmail { get; set; }
            public DateTime? RentalDate { get; set; }
            public DateTime? CreatedAt { get; set; }
            public List<int> SelectedInstruments { get; set; } = new();
            public int TotalPrice { get; set; }
        }

        public class InstrumentItem
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public int Price { get; set; }
            public string ImageUrl { get; set; }
        }
    }
}
