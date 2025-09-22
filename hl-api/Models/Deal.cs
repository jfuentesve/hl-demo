// hl-api/Models/Deal.cs
namespace HLApi.Models
{
public class Deal
    {
        public long Id { get; set; }                      // BIGINT
        public string Title { get; set; } = string.Empty;  // maps to Title if you don't rename in DB
        public string Client { get; set; } = string.Empty;
        public decimal Amount { get; set; }               // default precision via EF config
        public string? Description { get; set; }
        public string CurrencyCode { get; set; } = "USD"; // length 3; enforce in EF config
        public string Status { get; set; } = "New";
        public DateTime CreatedAt { get; set; }           // defaulted by DB to SYSUTCDATETIME()
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
    }
}