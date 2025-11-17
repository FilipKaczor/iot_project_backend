using IoTProject.API.Models;
using Microsoft.EntityFrameworkCore;

namespace IoTProject.API.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<SensorPh> SensorPh { get; set; }
    public DbSet<SensorTemp> SensorTemp { get; set; }
    public DbSet<SensorWeight> SensorWeight { get; set; }
    public DbSet<SensorOutside> SensorOutside { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User - unique email
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        // Sensor data - index na timestamp dla szybkich zapytań
        modelBuilder.Entity<SensorPh>()
            .HasIndex(s => s.Timestamp)
            .IsDescending();

        modelBuilder.Entity<SensorTemp>()
            .HasIndex(s => s.Timestamp)
            .IsDescending();

        modelBuilder.Entity<SensorWeight>()
            .HasIndex(s => s.Timestamp)
            .IsDescending();

        modelBuilder.Entity<SensorOutside>()
            .HasIndex(s => s.Timestamp)
            .IsDescending();

        // DeviceId index dla filtrowania
        modelBuilder.Entity<SensorPh>()
            .HasIndex(s => s.DeviceId);

        modelBuilder.Entity<SensorTemp>()
            .HasIndex(s => s.DeviceId);

        modelBuilder.Entity<SensorWeight>()
            .HasIndex(s => s.DeviceId);

        modelBuilder.Entity<SensorOutside>()
            .HasIndex(s => s.DeviceId);
    }
}

