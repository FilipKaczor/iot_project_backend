using IoTProject.API.Data;
using IoTProject.API.Models;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;

namespace IoTProject.API.Services;

public class WebSocketService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<WebSocketService> _logger;

    public WebSocketService(IServiceScopeFactory scopeFactory, ILogger<WebSocketService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    public async Task HandleWebSocketAsync(WebSocket webSocket)
    {
        _logger.LogInformation("New WebSocket connection established");
        var buffer = new byte[1024 * 4];

        try
        {
            while (webSocket.State == WebSocketState.Open)
            {
                var result = await webSocket.ReceiveAsync(
                    new ArraySegment<byte>(buffer), 
                    CancellationToken.None);

                if (result.MessageType == WebSocketMessageType.Close)
                {
                    await webSocket.CloseAsync(
                        WebSocketCloseStatus.NormalClosure, 
                        "Closing", 
                        CancellationToken.None);
                    _logger.LogInformation("WebSocket connection closed normally");
                    break;
                }

                var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                _logger.LogInformation($"Received message: {message}");

                // Process sensor data
                await ProcessSensorDataAsync(message);

                // Send acknowledgment
                var ackMessage = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(new 
                { 
                    status = "OK", 
                    timestamp = DateTime.UtcNow 
                }));
                
                await webSocket.SendAsync(
                    new ArraySegment<byte>(ackMessage), 
                    WebSocketMessageType.Text, 
                    true, 
                    CancellationToken.None);
            }
        }
        catch (WebSocketException ex)
        {
            _logger.LogError(ex, "WebSocket error");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing WebSocket message");
        }
    }

    private async Task ProcessSensorDataAsync(string message)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var data = JsonSerializer.Deserialize<SensorDataMessage>(message);
            if (data == null)
            {
                _logger.LogWarning("Failed to deserialize sensor data");
                return;
            }

            // Store data based on sensor type
            switch (data.Type?.ToLower())
            {
                case "ph":
                    await context.SensorPh.AddAsync(new SensorPh
                    {
                        DeviceId = data.DeviceId,
                        Value = data.Value,
                        Metadata = data.Metadata,
                        Timestamp = data.Timestamp ?? DateTime.UtcNow
                    });
                    break;

                case "temp":
                case "temperature":
                    await context.SensorTemp.AddAsync(new SensorTemp
                    {
                        DeviceId = data.DeviceId,
                        Value = data.Value,
                        Metadata = data.Metadata,
                        Timestamp = data.Timestamp ?? DateTime.UtcNow
                    });
                    break;

                case "weight":
                    await context.SensorWeight.AddAsync(new SensorWeight
                    {
                        DeviceId = data.DeviceId,
                        Value = data.Value,
                        Metadata = data.Metadata,
                        Timestamp = data.Timestamp ?? DateTime.UtcNow
                    });
                    break;

                case "outside":
                    await context.SensorOutside.AddAsync(new SensorOutside
                    {
                        DeviceId = data.DeviceId,
                        Value = data.Value,
                        Metadata = data.Metadata,
                        Timestamp = data.Timestamp ?? DateTime.UtcNow
                    });
                    break;

                default:
                    _logger.LogWarning($"Unknown sensor type: {data.Type}");
                    return;
            }

            await context.SaveChangesAsync();
            _logger.LogInformation($"Saved {data.Type} sensor data from device {data.DeviceId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving sensor data");
        }
    }

    private class SensorDataMessage
    {
        public string? Type { get; set; }
        public string DeviceId { get; set; } = string.Empty;
        public double Value { get; set; }
        public string? Metadata { get; set; }
        public DateTime? Timestamp { get; set; }
    }
}

