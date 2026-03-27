using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Text.Json;
using System.ComponentModel.DataAnnotations;
using Microsoft.Data.SqlClient;

namespace DuAnBai3.Areas.Identity.Pages.Instruments
{
    public class ConfirmModel : PageModel
    {
        [BindProperty]
        public InputModel Input { get; set; } = new();

        public class InputModel
        {
            [Required]
            public string CustomerName { get; set; }

            [Required]
            public string CustomerPhone { get; set; }

            [Required, EmailAddress]
            public string CustomerEmail { get; set; }

            [Required, DataType(DataType.Date)]
            public DateTime RentalDate { get; set; }

            [Required]
            public List<string> SelectedInstruments { get; set; } = new();

            [Required]
            public decimal TotalPrice { get; set; }
        }

        public IActionResult OnPost()
        {
            if (!ModelState.IsValid)
            {
                return BadRequest("❌ Dữ liệu không hợp lệ.");
            }

            string connectionString = "Server=LAPTOP-KS75264J\\SQLEXPRESS;Database=ĐACS;Trusted_Connection=True;TrustServerCertificate=True";
            using var conn = new SqlConnection(connectionString);
            conn.Open();

            var cmd = new SqlCommand(@"
                INSERT INTO Instruments (CustomerName, CustomerPhone, CustomerEmail, RentalDate, SelectedInstruments, TotalPrice, CreatedAt)
                OUTPUT INSERTED.Id
                VALUES (@Name, @Phone, @Email, @Date, @Selected, @Total, @Created)", conn);

            cmd.Parameters.AddWithValue("@Name", Input.CustomerName);
            cmd.Parameters.AddWithValue("@Phone", Input.CustomerPhone);
            cmd.Parameters.AddWithValue("@Email", Input.CustomerEmail);
            cmd.Parameters.AddWithValue("@Date", Input.RentalDate);
            cmd.Parameters.AddWithValue("@Selected", JsonSerializer.Serialize(Input.SelectedInstruments));
            cmd.Parameters.AddWithValue("@Total", Input.TotalPrice);
            cmd.Parameters.AddWithValue("@Created", DateTime.Now);

            try
            {
                int rentalId = (int)cmd.ExecuteScalar();
                return RedirectToPage("/Instruments/Invoice", new { area = "Identity", rental_id = rentalId });

            }
            catch (SqlException ex)
            {
                ModelState.AddModelError(string.Empty, "❌ Lỗi cơ sở dữ liệu: " + ex.Message);
                return Page();
            }
        }
    }
}
