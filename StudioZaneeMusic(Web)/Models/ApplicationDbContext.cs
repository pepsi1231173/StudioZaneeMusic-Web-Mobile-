using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using DuAnBai3.Models;
using System.Diagnostics.Metrics;
namespace DuAnBai3.Models
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Booking> Bookings { get; set; }
        public DbSet<Feedback> Feedbacks { get; set; }
        public DbSet<InstrumentRentals> InstrumentRentals { get; set; }
 
        public DbSet<MusicRequest> MusicRequests { get; set; }
        public DbSet<RecordingBooking> RecordingBookings { get; set; }

        // Nếu vẫn giữ các bảng sản phẩm từ hệ thống cũ
        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<ProductImage> ProductImages { get; set; }
        public DbSet<Room> Rooms { get; set; }
        public DbSet<MaintenanceRoom> MaintenanceRooms { get; set; }
        public DbSet<InstrumentMaintenance> InstrumentMaintenances { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Cấu hình: Khi xóa Category, thì gỡ liên kết trong Product
            modelBuilder.Entity<Product>()
                .HasOne(p => p.Category)
                .WithMany(c => c.Products)
                .HasForeignKey(p => p.CategoryId)
                .OnDelete(DeleteBehavior.SetNull); // 👈 Chỗ quan trọng

            // Cấu hình định dạng Price (nếu cần)
            modelBuilder.Entity<Product>()
                .Property(p => p.Price)
                .HasPrecision(18, 2);
            modelBuilder.Entity<InstrumentRentals>().ToTable("InstrumentRentals");

        }
    }
}
