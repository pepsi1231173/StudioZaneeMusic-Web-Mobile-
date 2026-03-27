using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DuAnBai3.Models
{
    [Table("InstrumentMaintenance")]
    public class InstrumentMaintenance
    {
        [Key]
        public int MaintenanceId { get; set; }

        [Required]
        public int InstrumentId { get; set; } // FK tới Product.Id hoặc InstrumentRentals.Id

        [Required]
        public DateTime StartDate { get; set; } = DateTime.Now;

        public DateTime? EndDate { get; set; }

        [MaxLength(255)]
        public string Description { get; set; }

        [MaxLength(50)]
        public string Status { get; set; } = "Ongoing"; // "Ongoing", "Completed"

        // ⚠ Không thêm navigation property nào nữa để tránh EF tạo cột ảo
    }
}
