using IoTProject.API.Data;
using IoTProject.API.Models;
using IoTProject.API.Models.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IoTProject.API.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class SensorDataController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<SensorDataController> _logger;

    public SensorDataController(
        ApplicationDbContext context,
        ILogger<SensorDataController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet("ph")]
    public async Task<ActionResult<SensorDataResponse<SensorPh>>> GetPhData([FromQuery] int limit = 10)
    {
        try
        {
            var data = await _context.SensorPh
                .OrderByDescending(s => s.Timestamp)
                .Take(limit)
                .ToListAsync();

            return Ok(new SensorDataResponse<SensorPh>
            {
                Success = true,
                Count = data.Count,
                Data = data
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching pH data");
            return StatusCode(500, new { error = "Server error fetching pH data" });
        }
    }

    [HttpGet("temp")]
    public async Task<ActionResult<SensorDataResponse<SensorTemp>>> GetTempData([FromQuery] int limit = 10)
    {
        try
        {
            var data = await _context.SensorTemp
                .OrderByDescending(s => s.Timestamp)
                .Take(limit)
                .ToListAsync();

            return Ok(new SensorDataResponse<SensorTemp>
            {
                Success = true,
                Count = data.Count,
                Data = data
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching temperature data");
            return StatusCode(500, new { error = "Server error fetching temperature data" });
        }
    }

    [HttpGet("weight")]
    public async Task<ActionResult<SensorDataResponse<SensorWeight>>> GetWeightData([FromQuery] int limit = 10)
    {
        try
        {
            var data = await _context.SensorWeight
                .OrderByDescending(s => s.Timestamp)
                .Take(limit)
                .ToListAsync();

            return Ok(new SensorDataResponse<SensorWeight>
            {
                Success = true,
                Count = data.Count,
                Data = data
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching weight data");
            return StatusCode(500, new { error = "Server error fetching weight data" });
        }
    }

    [HttpGet("outside")]
    public async Task<ActionResult<SensorDataResponse<SensorOutside>>> GetOutsideData([FromQuery] int limit = 10)
    {
        try
        {
            var data = await _context.SensorOutside
                .OrderByDescending(s => s.Timestamp)
                .Take(limit)
                .ToListAsync();

            return Ok(new SensorDataResponse<SensorOutside>
            {
                Success = true,
                Count = data.Count,
                Data = data
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching outside data");
            return StatusCode(500, new { error = "Server error fetching outside data" });
        }
    }

    [HttpGet("all")]
    public async Task<ActionResult<AllSensorDataResponse>> GetAllData([FromQuery] int limit = 10)
    {
        try
        {
            var phTask = _context.SensorPh.OrderByDescending(s => s.Timestamp).Take(limit).ToListAsync();
            var tempTask = _context.SensorTemp.OrderByDescending(s => s.Timestamp).Take(limit).ToListAsync();
            var weightTask = _context.SensorWeight.OrderByDescending(s => s.Timestamp).Take(limit).ToListAsync();
            var outsideTask = _context.SensorOutside.OrderByDescending(s => s.Timestamp).Take(limit).ToListAsync();

            await Task.WhenAll(phTask, tempTask, weightTask, outsideTask);

            return Ok(new AllSensorDataResponse
            {
                Success = true,
                Data = new SensorDataCollection
                {
                    Ph = await phTask,
                    Temp = await tempTask,
                    Weight = await weightTask,
                    Outside = await outsideTask
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching all data");
            return StatusCode(500, new { error = "Server error fetching all data" });
        }
    }

    [HttpGet("stats")]
    public async Task<ActionResult<StatsResponse>> GetStats()
    {
        try
        {
            var stats = new SensorStats
            {
                PhCount = await _context.SensorPh.CountAsync(),
                TempCount = await _context.SensorTemp.CountAsync(),
                WeightCount = await _context.SensorWeight.CountAsync(),
                OutsideCount = await _context.SensorOutside.CountAsync(),
                LastPhTimestamp = await _context.SensorPh.MaxAsync(s => (DateTime?)s.Timestamp),
                LastTempTimestamp = await _context.SensorTemp.MaxAsync(s => (DateTime?)s.Timestamp),
                LastWeightTimestamp = await _context.SensorWeight.MaxAsync(s => (DateTime?)s.Timestamp),
                LastOutsideTimestamp = await _context.SensorOutside.MaxAsync(s => (DateTime?)s.Timestamp)
            };

            return Ok(new StatsResponse
            {
                Success = true,
                Stats = stats
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching stats");
            return StatusCode(500, new { error = "Server error fetching stats" });
        }
    }
}

