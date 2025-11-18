using IoTProject.API.Data;
using IoTProject.API.Models;
using MQTTnet;
using MQTTnet.Server;
using System.Text;
using System.Text.Json;

namespace IoTProject.API.Services;

public class MqttService : IHostedService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<MqttService> _logger;
    private readonly IConfiguration _configuration;
    private MqttServer? _mqttServer;

    public MqttService(
        IServiceScopeFactory scopeFactory,
        ILogger<MqttService> logger,
        IConfiguration configuration)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        var port = _configuration.GetValue<int>("MqttSettings:Port", 1883);
        
        var optionsBuilder = new MqttServerOptionsBuilder()
            .WithDefaultEndpoint()
            .WithDefaultEndpointPort(port);

        var factory = new MqttFactory();
        _mqttServer = factory.CreateMqttServer(optionsBuilder.Build());
        
        // Event handlers
        _mqttServer.ValidatingConnectionAsync += args =>
        {
            _logger.LogInformation($"MQTT client connecting: {args.ClientId}");
            args.ReasonCode = MQTTnet.Protocol.MqttConnectReasonCode.Success;
            return Task.CompletedTask;
        };

        _mqttServer.InterceptingPublishAsync += async args =>
        {
            if (args.ApplicationMessage?.PayloadSegment == null)
                return;

            try
            {
                var topic = args.ApplicationMessage.Topic;
                var payload = Encoding.UTF8.GetString(args.ApplicationMessage.PayloadSegment);
                
                _logger.LogInformation($"MQTT message received on topic: {topic}, payload: {payload}");
                
                // Process sensor data
                await ProcessSensorDataAsync(topic, payload);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing MQTT message");
            }
        };

        _mqttServer.StartedAsync += args =>
        {
            _logger.LogInformation($"MQTT server started on port {port}");
            return Task.CompletedTask;
        };

        _mqttServer.ClientConnectedAsync += args =>
        {
            _logger.LogInformation($"MQTT client connected: {args.ClientId}");
            return Task.CompletedTask;
        };

        _mqttServer.ClientDisconnectedAsync += args =>
        {
            _logger.LogInformation($"MQTT client disconnected: {args.ClientId}");
            return Task.CompletedTask;
        };

        await _mqttServer.StartAsync();
        _logger.LogInformation($"✅ MQTT server listening on port {port}");
    }

    public async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_mqttServer != null)
        {
            await _mqttServer.StopAsync();
            _logger.LogInformation("MQTT server stopped");
        }
    }

    private async Task ProcessSensorDataAsync(string topic, string payload)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            // Parse JSON payload
            var data = JsonSerializer.Deserialize<SensorDataMessage>(payload);
            if (data == null)
            {
                _logger.LogWarning("Failed to deserialize sensor data from MQTT message");
                return;
            }

            // Extract sensor type from topic if not in payload
            // Topics: sensors/ph, sensors/temp, sensors/weight, sensors/outside
            if (string.IsNullOrEmpty(data.Type) && topic.Contains('/'))
            {
                var topicParts = topic.Split('/');
                if (topicParts.Length > 1)
                {
                    data.Type = topicParts[^1]; // Last part of topic
                }
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
                    _logger.LogWarning($"Unknown sensor type: {data.Type} (topic: {topic})");
                    return;
            }

            await context.SaveChangesAsync();
            _logger.LogInformation($"Saved {data.Type} sensor data from device {data.DeviceId} via MQTT");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving sensor data from MQTT");
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
