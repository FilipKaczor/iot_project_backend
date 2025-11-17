using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IoTProject.API.Models;

public abstract class SensorDataBase
{
    [Key]
    public int Id { get; set; }

    [MaxLength(100)]
    public string? DeviceId { get; set; }

    [Required]
    public double Value { get; set; }

    public string? Metadata { get; set; } // JSON string

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

[Table("SensorPh")]
public class SensorPh : SensorDataBase { }

[Table("SensorTemp")]
public class SensorTemp : SensorDataBase { }

[Table("SensorWeight")]
public class SensorWeight : SensorDataBase { }

[Table("SensorOutside")]
public class SensorOutside : SensorDataBase { }

