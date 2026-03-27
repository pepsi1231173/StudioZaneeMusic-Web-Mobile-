using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DuAnBai3.Models
{
    public class Booking
    {
        public int Id { get; set; }

        [Required]
        public string RoomId { get; set; }

        [Required, StringLength(255)]
        public string CustomerName { get; set; }

        [Required, StringLength(20)]
        public string CustomerPhone { get; set; }

        [Required, StringLength(255)]
        public string CustomerEmail { get; set; }

        [Required]
        public DateTime RentalDate { get; set; }

        [Required]
        public TimeSpan StartTime { get; set; }

        public TimeSpan? EndTime { get; set; }

        public int RentalDuration { get; set; }

        public int GuestCount { get; set; }

        public string Status { get; set; } = "pending";

        public int Price { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? UpdatedAt { get; set; }
        public bool IsArchived { get; set; } = false;
        public int DailyBookingNumber { get; set; }

        // ✅ Thuộc tính tính toán, không lưu DB
        [NotMapped]
        public DateTime StartDateTime => RentalDate.Date + StartTime;

        [NotMapped]
        public DateTime? EndDateTime =>
            EndTime.HasValue ? RentalDate.Date + EndTime.Value : null;
    }
}
