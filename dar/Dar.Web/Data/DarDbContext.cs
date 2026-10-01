using Microsoft.EntityFrameworkCore;

namespace Dar.Web.Data;

public class DarDbContext(DbContextOptions<DarDbContext> options) : DbContext(options)
{
    public DbSet<WaitlistEntry> Waitlist => Set<WaitlistEntry>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<WaitlistEntry>(e =>
        {
            e.Property(x => x.Name).HasMaxLength(80);
            e.Property(x => x.Contact).HasMaxLength(120);
            e.Property(x => x.Country).HasMaxLength(4);
            e.Property(x => x.Role).HasMaxLength(16);
            e.Property(x => x.Locale).HasMaxLength(4);
            e.HasIndex(x => x.Contact).IsUnique();
        });
    }
}
