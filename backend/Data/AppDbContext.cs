using Microsoft.EntityFrameworkCore;
using Backend_Nhom6_QuanLyChiTieu.Models;

namespace Backend_Nhom6_QuanLyChiTieu.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
        public DbSet<Transaction> Transactions { get; set; }
    }
}