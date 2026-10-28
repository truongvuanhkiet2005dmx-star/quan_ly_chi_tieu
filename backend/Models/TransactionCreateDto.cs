using System.ComponentModel.DataAnnotations;

namespace Backend_Nhom6_QuanLyChiTieu.Models
{
    public class TransactionCreateDto
    {
        [Required(ErrorMessage = "EventId là bắt buộc.")]
        [StringLength(200, MinimumLength = 1, ErrorMessage = "EventId phải từ 1 đến 200 ký tự.")]
        public string EventId { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Số tiền phải lớn hơn 0.")]
        public int Amount { get; set; }

        [Required(ErrorMessage = "Type là bắt buộc.")]
        [StringLength(50)]
        public string Type { get; set; } = string.Empty;

        [Required(ErrorMessage = "Source là bắt buộc.")]
        [StringLength(100)]
        public string Source { get; set; } = string.Empty;

        [StringLength(100)]
        public string BankName { get; set; } = string.Empty;

        [StringLength(100)]
        public string PackageName { get; set; } = string.Empty;

        public DateTime OccurredAt { get; set; }

        [Required(ErrorMessage = "CategoryName là bắt buộc.")]
        [StringLength(100)]
        public string CategoryName { set; get; } = string.Empty;

        [StringLength(1000)]
        public string Note { get; set; } = string.Empty;
    }
}