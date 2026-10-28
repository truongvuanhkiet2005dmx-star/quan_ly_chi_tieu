using Microsoft.EntityFrameworkCore;
using Backend_Nhom6_QuanLyChiTieu.Models;

namespace Backend_Nhom6_QuanLyChiTieu.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Transaction> Transactions { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Chống trùng lặp tuyệt đối ở mức Database
            modelBuilder.Entity<Transaction>()
                .HasIndex(t => new { t.Uid, t.EventId })
                .IsUnique();

            modelBuilder.Entity<Transaction>()
                .HasIndex(t => new { t.Uid, t.OccurredAt });
        }
    }
}