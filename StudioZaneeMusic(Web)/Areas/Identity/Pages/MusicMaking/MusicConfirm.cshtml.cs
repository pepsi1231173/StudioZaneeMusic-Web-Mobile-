using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using DuAnBai3.Data;
using DuAnBai3.Models;

namespace DuAnBai3.Pages
{
    public class MusicConfirmModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public MusicConfirmModel(ApplicationDbContext context)
        {
            _context = context;
        }

        [BindProperty]
        public MusicRequest MusicRequest { get; set; }

        public IActionResult OnGet(int id)
        {
            MusicRequest = _context.MusicRequests.Find(id);
            if (MusicRequest == null)
            {
                return NotFound();
            }

            return Page();
        }
    }
}
