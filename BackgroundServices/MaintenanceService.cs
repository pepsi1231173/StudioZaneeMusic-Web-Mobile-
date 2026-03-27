using System;
using System.Collections.Generic;
using System.Linq;
using DuAnBai3.Models;  // Chứa entity MaintenanceRoom
using Microsoft.EntityFrameworkCore;

namespace DuAnBai3.Services
{
    public class MaintenanceService
    {
        private readonly ApplicationDbContext _context;

        public MaintenanceService(ApplicationDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Cập nhật danh sách phòng đang bảo trì.
        /// Nếu phòng đã có và đang active thì giữ nguyên.
        /// Nếu phòng mới thì thêm mới.
        /// Nếu phòng không còn trong danh sách mới thì tắt bảo trì.
        /// </summary>
        public void SetMaintenance(List<string> roomIds)
        {
            var currentMaintenances = _context.MaintenanceRooms.Where(m => m.IsActive).ToList();

            // Tắt bảo trì phòng không còn trong danh sách mới
            foreach (var maintenance in currentMaintenances)
            {
                if (!roomIds.Contains(maintenance.RoomId))
                {
                    maintenance.IsActive = false;
                }
            }

            // Thêm mới phòng chưa có trong danh sách bảo trì active
            foreach (var roomId in roomIds)
            {
                if (!currentMaintenances.Any(m => m.RoomId == roomId && m.IsActive))
                {
                    _context.MaintenanceRooms.Add(new MaintenanceRoom
                    {
                        RoomId = roomId,
                        IsActive = true,
                        CreatedAt = DateTime.Now
                    });
                }
            }

            _context.SaveChanges();
        }

        /// <summary>
        /// Xóa hết các phòng đang bảo trì (tắt bảo trì hết).
        /// </summary>
        public void ClearMaintenance()
        {
            var activeRooms = _context.MaintenanceRooms.Where(m => m.IsActive).ToList();
            foreach (var room in activeRooms)
            {
                room.IsActive = false;
            }
            _context.SaveChanges();
        }

        /// <summary>
        /// Lấy danh sách phòng đang bảo trì (RoomId).
        /// </summary>
        public List<string> GetMaintenanceRooms()
        {
            return _context.MaintenanceRooms
                .Where(m => m.IsActive)
                .Select(m => m.RoomId)
                .ToList();
        }

        /// <summary>
        /// Kiểm tra phòng có đang bảo trì không.
        /// </summary>
        public bool IsInMaintenance(string roomId)
        {
            if (string.IsNullOrWhiteSpace(roomId)) return false;
            return _context.MaintenanceRooms.Any(m => m.RoomId == roomId && m.IsActive);
        }
    }
}
