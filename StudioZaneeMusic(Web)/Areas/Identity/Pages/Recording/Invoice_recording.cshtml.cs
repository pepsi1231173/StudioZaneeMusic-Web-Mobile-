using DuAnBai3.Data;
using DuAnBai3.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace DuAnBai3.Areas.Identity.Pages.Recording
{
    public class InvoiceRecordingModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public InvoiceRecordingModel(ApplicationDbContext context)
        {
            _context = context;
        }

        public RecordingBooking Booking { get; set; }

        public IActionResult OnGet(int id)
        {
            Booking = _context.Set<RecordingBooking>().FirstOrDefault(b => b.Id == id);
            if (Booking == null)
            {
                return NotFound();
            }
            return Page();
        }
    }
}
    