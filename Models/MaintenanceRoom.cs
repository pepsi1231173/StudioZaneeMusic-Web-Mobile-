using System;

namespace DuAnBai3.Models
{
    public class MaintenanceRoom
    {
        public int Id { get; set; }

        // Mã phòng bị bảo trì (A, B, C, ...)
        public string RoomId { get; set; } = "";

        // Thời gian bắt đầu bảo trì
        public DateTime StartDate { get; set; }

        // Thời gian kết thúc bảo trì
        public DateTime EndDate { get; set; }

        // Ghi chú tùy chọn
        public string? Description { get; set; }

        // Trạng thái bảo trì (đang hoạt động hoặc đã kết thúc)
        public bool IsActive { get; set; } = true;

        // Ngày tạo bản ghi
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
