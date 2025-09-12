// hl-api/Controllers/DealsController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HLApi.Data;
using HLApi.Dtos;
using HLApi.Models;


namespace HLApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DealsController : ControllerBase
    {
        private readonly AppDbContext _context;


        public DealsController(AppDbContext context)
        {
            _context = context;
        }


        [HttpGet]
        public async Task<ActionResult<IEnumerable<DealDto>>> GetDeals()
        {
            var deals = await _context.Deals
            .Select(d => new DealDto
            {
                Id = d.Id,
                Name = d.Name,
                Client = d.Client,
                Amount = d.Amount,
                CreatedAt = d.CreatedAt
            })
            .ToListAsync();


            return Ok(deals);
        }


        [HttpGet("{id}")]
        public async Task<ActionResult<DealDto>> GetDeal(int id)
        {
            var deal = await _context.Deals.FindAsync(id);
            if (deal == null) return NotFound();


            return Ok(new DealDto
            {
                Id = deal.Id,
                Name = deal.Name,
                Client = deal.Client,
                Amount = deal.Amount,
                CreatedAt = deal.CreatedAt
            });
        }


        [HttpPost]
        public async Task<ActionResult<DealDto>> CreateDeal(DealCreateDto dto)
        {
            var deal = new Deal
            {
                Name = dto.Name,
                Client = dto.Client,
                Amount = dto.Amount,
                CreatedAt = DateTime.UtcNow
            };
            _context.Deals.Add(deal);
            await _context.SaveChangesAsync();


            return CreatedAtAction(nameof(GetDeal), new { id = deal.Id }, new DealDto
            {
                Id = deal.Id,
                Name = deal.Name,
                Client = deal.Client,
                Amount = deal.Amount,
                CreatedAt = deal.CreatedAt
            });
        }


        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateDeal(int id, DealUpdateDto dto)
        {
            var deal = await _context.Deals.FindAsync(id);
            if (deal == null) return NotFound();


            deal.Name = dto.Name;
            deal.Client = dto.Client;
            deal.Amount = dto.Amount;


            await _context.SaveChangesAsync();
            return NoContent();
        }


        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDeal(int id)
        {
            var deal = await _context.Deals.FindAsync(id);
            if (deal == null) return NotFound();


            _context.Deals.Remove(deal);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}