// hl-api/Data/AppDbContext.cs
using Microsoft.EntityFrameworkCore;
using HLApi.Models;


namespace HLApi.Data
{
public class AppDbContext : DbContext
{
public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }


public DbSet<Deal> Deals { get; set; } = null!;
}
}