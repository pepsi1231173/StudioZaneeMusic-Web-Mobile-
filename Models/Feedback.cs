using System.ComponentModel.DataAnnotations;

namespace DuAnBai3.Models
{
    public class Feedback
    {
        public int Id { get; set; }

        [Required]
        public string Name { get; set; }

        [Required, EmailAddress]
        public string Email { get; set; }

        [Required]
        public string Phone { get; set; }

        [Range(1, 5)]
        public byte Rating { get; set; }

        [Required]
        public string Message { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public bool IsNew { get; set; } = true;
    }
}
