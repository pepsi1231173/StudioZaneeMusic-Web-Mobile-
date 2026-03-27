using System;
using System.ComponentModel.DataAnnotations;

namespace DuAnBai3.Models
{
    public class RecordingBooking
    {
        public int Id { get; set; }

        [Required]
        public string CustomerName { get; set; }

        [Required, EmailAddress]
        public string CustomerEmail { get; set; }

        [Required]
        public string CustomerPhone { get; set; }

        [Required]
        public string RecordingPackage { get; set; }

        public int Price { get; set; }

        public DateTime RecordingDate { get; set; }

        public TimeSpan RecordingTime { get; set; }

        [Range(1, 8)]
        public int Duration { get; set; } = 1; // Thời lượng thu âm (giờ)

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public string Status { get; set; } = "pending";
    }
}
