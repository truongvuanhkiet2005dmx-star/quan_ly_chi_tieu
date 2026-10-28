using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Backend_Nhom6_QuanLyChiTieu.Data;
using Backend_Nhom6_QuanLyChiTieu.Models;

namespace Backend_Nhom6_QuanLyChiTieu.Controllers
{
    [Authorize]
    [ApiController]
    public class TransactionsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TransactionsController(AppDbContext context)
        {
            _context = context;
        }

        [AllowAnonymous]
        [HttpGet("/health")]
        public IActionResult HealthCheck() => Ok(new { status = "Backend Secured with Firebase JWT!" });

        [HttpGet("api/transactions")]
        public async Task<IActionResult> GetTransactions()
        {
            var uid = GetFirebaseUid();
            if (string.IsNullOrEmpty(uid)) return Unauthorized();

            var data = await _context.Transactions
                .Where(t => t.Uid == uid)
                .OrderByDescending(t => t.OccurredAt)
                .ToListAsync();

            return Ok(data);
        }

        [HttpPost("api/transactions")]
        public async Task<IActionResult> CreateTransaction([FromBody] TransactionCreateDto dto)
        {
            if (dto.OccurredAt == default)
                return BadRequest(new { success = false, message = "OccurredAt phải là thời điểm hợp lệ." });

            var uid = GetFirebaseUid();
            if (string.IsNullOrEmpty(uid)) return Unauthorized();

            // Kiểm tra trùng cấp ứng dụng
            var existingTx = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Uid == uid && t.EventId == dto.EventId);

            if (existingTx != null)
                return HandleDuplicate(existingTx, dto);

            var newTx = new Transaction
            {
                Uid = uid,
                EventId = dto.EventId,
                Amount = dto.Amount,
                Type = dto.Type,
                Source = dto.Source,
                BankName = dto.BankName,
                PackageName = dto.PackageName,
                OccurredAt = dto.OccurredAt,
                CategoryName = dto.CategoryName,
                Note = dto.Note
            };

            try
            {
                _context.Transactions.Add(newTx);
                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Lưu thành công!" });
            }
            catch (DbUpdateException ex) when (ex.InnerException?.Message.Contains("UNIQUE constraint failed") == true)
            {
                // Bắt lỗi khi 2 request đến cùng một mili-giây qua được lớp kiểm tra ứng dụng
                var concurrentTx = await _context.Transactions
                    .FirstOrDefaultAsync(t => t.Uid == uid && t.EventId == dto.EventId);

                if (concurrentTx != null) return HandleDuplicate(concurrentTx, dto);

                throw;
            }
        }

        private string? GetFirebaseUid()
        {
            // MapInboundClaims = false giữ claim Firebase chuẩn; UID nằm trong "sub".
            return User.FindFirst("sub")?.Value;
        }

        private IActionResult HandleDuplicate(Transaction existing, TransactionCreateDto incoming)
        {
            bool isSameData = existing.EventId == incoming.EventId
                           && existing.Amount == incoming.Amount
                           && existing.Type == incoming.Type
                           && existing.Source == incoming.Source
                           && existing.BankName == incoming.BankName
                           && existing.PackageName == incoming.PackageName
                           && existing.OccurredAt == incoming.OccurredAt
                           && existing.CategoryName == incoming.CategoryName
                           && existing.Note == incoming.Note;

            if (isSameData)
                return Ok(new { success = true, message = "Giao dịch đã tồn tại, bỏ qua lưu trùng.", transactionId = existing.Id });

            return Conflict(new { success = false, message = "Trùng EventId nhưng dữ liệu giao dịch khác biệt." });
        }
    }
}