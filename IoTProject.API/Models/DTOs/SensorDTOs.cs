namespace IoTProject.API.Models.DTOs;

public class SensorDataResponse<T> where T : SensorDataBase
{
    public bool Success { get; set; } = true;
    public int Count { get; set; }
    public List<T> Data { get; set; } = new();
}

public class AllSensorDataResponse
{
    public bool Success { get; set; } = true;
    public SensorDataCollection Data { get; set; } = new();
}

public class SensorDataCollection
{
    public List<SensorPh> Ph { get; set; } = new();
    public List<SensorTemp> Temp { get; set; } = new();
    public List<SensorWeight> Weight { get; set; } = new();
    public List<SensorOutside> Outside { get; set; } = new();
}

public class StatsResponse
{
    public bool Success { get; set; } = true;
    public SensorStats Stats { get; set; } = new();
}

public class SensorStats
{
    public int PhCount { get; set; }
    public int TempCount { get; set; }
    public int WeightCount { get; set; }
    public int OutsideCount { get; set; }
    public DateTime? LastPhTimestamp { get; set; }
    public DateTime? LastTempTimestamp { get; set; }
    public DateTime? LastWeightTimestamp { get; set; }
    public DateTime? LastOutsideTimestamp { get; set; }
}

