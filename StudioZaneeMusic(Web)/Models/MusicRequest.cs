using System.ComponentModel.DataAnnotations;

namespace DuAnBai3.Models
{
    public class MusicRequest
    {
        public int Id { get; set; }

        [Required]
        public string MusicGenre { get; set; }

        [Required]
        public string MusicDescription { get; set; }

        [Required]
        public string CustomerName { get; set; }

        [Required, EmailAddress]
        public string CustomerEmail { get; set; }

        [Required]
        public string CustomerPhone { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public string Status { get; set; } = "pending";
    }
}
