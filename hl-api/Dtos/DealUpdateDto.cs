// hl-api/Dtos/DealUpdateDto.cs
namespace HLApi.Dtos
{
public class DealUpdateDto
{
public string Name { get; set; } = string.Empty;
public string Client { get; set; } = string.Empty;
public decimal Amount { get; set; }
}
}