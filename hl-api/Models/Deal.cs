// hl-api/Models/Deal.cs
namespace HLApi.Models
{
public class Deal
{
public int Id { get; set; }
public string Name { get; set; } = string.Empty;
public string Client { get; set; } = string.Empty;
public decimal Amount { get; set; }
public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
}