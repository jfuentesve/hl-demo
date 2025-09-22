// hl-api/Dtos/DealCreateDto.cs
namespace HLApi.Dtos
{
    public class DealCreateDto
    {
        public string Title { get; set; } = string.Empty;
        public string Client { get; set; } = string.Empty;
        public decimal Amount { get; set; }
    }
}