// hl-api/Dtos/DealDto.cs
namespace HLApi.Dtos
{
public class DealDto
{
public int Id { get; set; }
public string Name { get; set; } = string.Empty;
public string Client { get; set; } = string.Empty;
public decimal Amount { get; set; }
public DateTime CreatedAt { get; set; }
}
}