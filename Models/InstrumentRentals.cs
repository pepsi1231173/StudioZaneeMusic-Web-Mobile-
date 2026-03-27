using System;
using System.ComponentModel.DataAnnotations;

namespace DuAnBai3.Models
{
    public class InstrumentRentals
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập họ tên.")]
        public string CustomerName { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
        public string CustomerPhone { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string CustomerEmail { get; set; }

        public DateTime? RentalDate { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn ít nhất 1 nhạc cụ.")]
        public string SelectedInstruments { get; set; }  // JSON list Ids của Product

        public int? TotalPrice { get; set; }
        public DateTime? CreatedAt { get; set; } = DateTime.Now;
        public string Status { get; set; } = "Pending";
        public bool IsUnderMaintenance { get; set; } = false;

        // Navigation
        public virtual ICollection<InstrumentMaintenance> Maintenances { get; set; } = new List<InstrumentMaintenance>();
    }

}
