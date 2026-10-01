using LuluaServices.Models;
using Microsoft.EntityFrameworkCore;

namespace LuluaServices.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Booking> Bookings => Set<Booking>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<Booking>(e =>
        {
            e.HasIndex(x => x.Status);
            e.HasIndex(x => x.CreatedAtUtc);
            e.Property(x => x.Status).HasConversion<int>();
        });
    }
}
