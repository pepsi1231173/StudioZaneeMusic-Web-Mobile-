using DuAnBai3.Data;
using DuAnBai3.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;

namespace DuAnBai3.Pages
{
    public class MusicRequestModel : PageModel
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public MusicRequestModel(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        public class InputModel
        {
            [BindProperty] public string MusicGenre { get; set; }
            [BindProperty] public string MusicDescription { get; set; }
            [BindProperty] public string CustomerName { get; set; }
            [BindProperty] public string CustomerEmail { get; set; }
            [BindProperty] public string CustomerPhone { get; set; }
        }

        [BindProperty]
        public InputModel Input { get; set; } = new InputModel();

        public async Task<IActionResult> OnGetAsync()
        {
            if (User.Identity.IsAuthenticated)
            {
                var user = await _userManager.GetUserAsync(User);
                if (user != null)
                {
                    Input.CustomerName = user.FullName ?? user.UserName;
                    Input.CustomerEmail = user.Email;
                    Input.CustomerPhone = user.PhoneNumber;
                }
            }

            return Page();
        }

        public IActionResult OnPost()
        {
            if (!ModelState.IsValid) return Page();

            var musicRequest = new MusicRequest
            {
                MusicGenre = Input.MusicGenre,
                MusicDescription = Input.MusicDescription,
                CustomerName = Input.CustomerName,
                CustomerEmail = Input.CustomerEmail,
                CustomerPhone = Input.CustomerPhone,
                CreatedAt = DateTime.Now,
                Status = "pending"
            };

            _context.MusicRequests.Add(musicRequest);
            _context.SaveChanges();

            return Redirect($"/Music/InvoiceMusic/{musicRequest.Id}");
        }
    }
}
