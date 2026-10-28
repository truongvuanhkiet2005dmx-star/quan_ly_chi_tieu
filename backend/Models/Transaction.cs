using System.ComponentModel.DataAnnotations;

namespace Backend_Nhom6_QuanLyChiTieu.Models
{
    public class Transaction
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string EventId { get; set; } = string.Empty;

        [Required]
        public string Uid { get; set; } = string.Empty; // Firebase UID

        public int Amount { get; set; }
        public string Type { get; set; } = string.Empty;
        public string Source { get; set; } = string.Empty;
        public string BankName { get; set; } = string.Empty;
        public string PackageName { get; set; } = string.Empty;
        public DateTime OccurredAt { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string Note { get; set; } = string.Empty;
    }
}