using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using DuAnBai3.Models;
using System.Threading.Tasks;

namespace DuAnBai3.Pages.Feedbacks
{
    public class IndexModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public IndexModel(ApplicationDbContext context)
        {
            _context = context;
        }

        [BindProperty]
        public Feedback Feedback { get; set; }

        public void OnGet()
        {
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
                return Page();

            Feedback.CreatedAt = DateTime.Now;
            _context.Feedbacks.Add(Feedback);
            await _context.SaveChangesAsync();

            TempData["Success"] = "Cảm ơn bạn đã gửi phản hồi!";
            return RedirectToPage(); // reload chính nó
        }
    }
}
