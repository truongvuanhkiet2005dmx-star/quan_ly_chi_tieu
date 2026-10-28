using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Backend_Nhom6_QuanLyChiTieu.Data;
using Backend_Nhom6_QuanLyChiTieu.Models;

namespace Backend_Nhom6_QuanLyChiTieu.Controllers
{
    [ApiController]
    public class TransactionsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TransactionsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("/health")]
        public IActionResult HealthCheck() => Ok(new { status = "Server đang chạy ngon lành!" });

        [HttpGet("api/transactions")]
        public async Task<IActionResult> GetTransactions()
        {
            var data = await _context.Transactions.OrderByDescending(t => t.OccurredAt).ToListAsync();
            return Ok(data);
        }

        [HttpPost("api/transactions")]
        public async Task<IActionResult> CreateTransaction([FromBody] Transaction transaction)
        {
            if (transaction == null || string.IsNullOrEmpty(transaction.EventId))
                return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ hoặc thiếu EventId." });

            bool exists = await _context.Transactions.AnyAsync(t => t.EventId == transaction.EventId);
            if (exists)
                return Ok(new { success = true, message = "Giao dịch đã tồn tại, bỏ qua lưu trùng." });

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            Console.WriteLine($"[Ting Ting] Đã lưu giao dịch: {transaction.Amount} VNĐ từ {transaction.BankName}");
            return Ok(new { success = true, message = "Lưu thành công!" });
        }
    }
}