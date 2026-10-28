using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Backend_Nhom6_QuanLyChiTieu.Data;
using Backend_Nhom6_QuanLyChiTieu.Models;

namespace Backend_Nhom6_QuanLyChiTieu.Controllers
{
    [Authorize]
    [ApiController]
    [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("transactions")]
    public class TransactionsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TransactionsController(AppDbContext context)
        {
            _context = context;
        }

        [AllowAnonymous]
        [HttpGet("/health")]
        public async Task<IActionResult> HealthCheck()
        {
            var databaseConnected = await _context.Database.CanConnectAsync();
            return Ok(new { status = "ok", database = databaseConnected ? "connected" : "disconnected" });
        }

        [HttpGet("api/transactions")]
        public async Task<IActionResult> GetTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var uid = GetFirebaseUid();
            if (string.IsNullOrEmpty(uid)) return Unauthorized();
            if (page < 1 || pageSize < 1 || pageSize > 100)
                return BadRequest(new { success = false, message = "page phải >= 1 và pageSize từ 1 đến 100." });

            var query = _context.Transactions.Where(t => t.Uid == uid);
            var total = await query.CountAsync();
            var data = await query
                .OrderByDescending(t => t.OccurredAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return Ok(new { page, pageSize, total, data });
        }

        [HttpGet("api/transactions/{id:int}")]
        public async Task<IActionResult> GetTransaction(int id)
        {
            var uid = GetFirebaseUid();
            if (string.IsNullOrEmpty(uid)) return Unauthorized();

            var transaction = await _context.Transactions.FirstOrDefaultAsync(t => t.Id == id && t.Uid == uid);
            return transaction == null
                ? NotFound(new { success = false, message = "Không tìm thấy giao dịch." })
                : Ok(transaction);
        }

        [HttpDelete("api/transactions/{id:int}")]
        public async Task<IActionResult> DeleteTransaction(int id)
        {
            var uid = GetFirebaseUid();
            if (string.IsNullOrEmpty(uid)) return Unauthorized();

            var transaction = await _context.Transactions.FirstOrDefaultAsync(t => t.Id == id && t.Uid == uid);
            if (transaction == null)
                return NotFound(new { success = false, message = "Không tìm thấy giao dịch." });

            _context.Transactions.Remove(transaction);
            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Xóa giao dịch thành công." });
        }

        [HttpPost("api/transactions")]
        public async Task<IActionResult> CreateTransaction([FromBody] TransactionCreateDto dto)
        {
            if (dto.OccurredAt == default || dto.OccurredAt.Year < 1900)
                return BadRequest(new { success = false, message = "OccurredAt phải là thời điểm hợp lệ." });

            var occurredAtUtc = dto.OccurredAt.UtcDateTime;


            var uid = GetFirebaseUid();
            if (string.IsNullOrEmpty(uid)) return Unauthorized();

            // Kiểm tra trùng cấp ứng dụng
            var existingTx = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Uid == uid && t.EventId == dto.EventId);

            if (existingTx != null)
                return HandleDuplicate(existingTx);

            var newTx = new Transaction
            {
                Uid = uid,
                EventId = dto.EventId,
                Amount = dto.Amount,
                Type = dto.Type,
                Source = dto.Source,
                BankName = dto.BankName,
                PackageName = dto.PackageName,
                OccurredAt = occurredAtUtc,
                CategoryName = dto.CategoryName,
                Note = dto.Note
            };

            try
            {
                _context.Transactions.Add(newTx);
                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Lưu thành công!" });
            }
            catch (DbUpdateException)
            {
                // Bắt lỗi race-condition; chỉ trả duplicate khi bản ghi tồn tại.
                var concurrentTx = await _context.Transactions
                    .FirstOrDefaultAsync(t => t.Uid == uid && t.EventId == dto.EventId);

                if (concurrentTx != null)
                    return HandleDuplicate(concurrentTx);

                throw;
            }
        }

        private string? GetFirebaseUid()
        {
            // MapInboundClaims = false giữ claim Firebase chuẩn; UID nằm trong "sub".
            return User.FindFirst("sub")?.Value;
        }

        private IActionResult HandleDuplicate(Transaction existing)
        {
            // EventId đã là khóa idempotency (Uid, EventId). Retry cùng EventId phải luôn
            // trả 200 và không ghi đè hoặc chấp nhận payload khác làm transaction mới.
            return Ok(new
            {
                success = true,
                message = "Giao dịch đã tồn tại, bỏ qua lưu trùng.",
                transactionId = existing.Id
            });
        }
    }
}