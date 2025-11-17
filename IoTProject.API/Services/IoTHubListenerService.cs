using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;
using IoTProject.API.Data;
using IoTProject.API.Hubs;
using IoTProject.API.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Text;
using System.Text.Json;

namespace IoTProject.API.Services;

public class IoTHubListenerService : BackgroundService
{
    private readonly ILogger<IoTHubListenerService> _logger;
    private readonly IConfiguration _configuration;
    private readonly IServiceProvider _serviceProvider;
    private readonly IHubContext<SensorDataHub> _hubContext;
    private EventProcessorClient? _processor;

    public IoTHubListenerService(
        ILogger<IoTHubListenerService> logger,
        IConfiguration configuration,
        IServiceProvider serviceProvider,
        IHubContext<SensorDataHub> hubContext)
    {
        _logger = logger;
        _configuration = configuration;
        _serviceProvider = serviceProvider;
        _hubContext = hubContext;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var eventHubConnectionString = _configuration["AzureIoTHub:EventHubConnectionString"];
        var consumerGroup = _configuration["AzureIoTHub:ConsumerGroup"] ?? "$Default";
        var blobConnectionString = _configuration["AzureIoTHub:BlobStorageConnectionString"];

        if (string.IsNullOrEmpty(eventHubConnectionString) || 
            eventHubConnectionString.Contains("your-endpoint"))
        {
            _logger.LogWarning("⚠️  IoT Hub Event Hub endpoint not configured. Skipping listener...");
            return;
        }

        try
        {
            _logger.LogInformation("🔄 Starting IoT Hub Listener...");

            // Jeśli mamy blob storage (dla checkpointów)
            if (!string.IsNullOrEmpty(blobConnectionString) && 
                !blobConnectionString.Contains("youraccount"))
            {
                var blobContainerClient = new BlobContainerClient(blobConnectionString, "iot-checkpoints");
                await blobContainerClient.CreateIfNotExistsAsync(cancellationToken: stoppingToken);

                _processor = new EventProcessorClient(
                    blobContainerClient,
                    consumerGroup,
                    eventHubConnectionString);

                _processor.ProcessEventAsync += ProcessEventHandler;
                _processor.ProcessErrorAsync += ProcessErrorHandler;

                await _processor.StartProcessingAsync(stoppingToken);
                _logger.LogInformation("✅ IoT Hub Listener started (with checkpoints)");
            }
            else
            {
                // Bez blob storage - prostszy listener
                await RunSimpleListenerAsync(eventHubConnectionString, consumerGroup, stoppingToken);
            }

            // Keep running until cancelled
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ IoT Hub Listener error");
        }
    }

    private async Task RunSimpleListenerAsync(
        string connectionString, 
        string consumerGroup, 
        CancellationToken cancellationToken)
    {
        var client = new EventHubConsumerClient(consumerGroup, connectionString);
        _logger.LogInformation("✅ IoT Hub Listener started (simple mode, no checkpoints)");

        try
        {
            await foreach (var partitionEvent in client.ReadEventsAsync(cancellationToken))
            {
                if (partitionEvent.Data == null) continue;
                await ProcessEventDataAsync(partitionEvent.Data, cancellationToken);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("IoT Hub Listener stopped");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in simple listener");
        }
        finally
        {
            await client.DisposeAsync();
        }
    }

    private async Task ProcessEventHandler(ProcessEventArgs args)
    {
        try
        {
            await ProcessEventDataAsync(args.Data, args.CancellationToken);
            await args.UpdateCheckpointAsync(args.CancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing event");
        }
    }

    private async Task ProcessEventDataAsync(EventData eventData, CancellationToken cancellationToken)
    {
        try
        {
            var deviceId = eventData.SystemProperties.TryGetValue("iothub-connection-device-id", out var id)
                ? id?.ToString()
                : "unknown";

            var messageBody = Encoding.UTF8.GetString(eventData.EventBody.ToArray());
            _logger.LogInformation($"📨 Message from device {deviceId}: {messageBody}");

            // Parse JSON
            using var doc = JsonDocument.Parse(messageBody);
            var root = doc.RootElement;

            // Save to database
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var metadata = messageBody; // Zapisz cały JSON jako metadata
            var timestamp = DateTime.UtcNow;

            // pH
            if (root.TryGetProperty("ph", out var phElement))
            {
                var ph = new SensorPh
                {
                    DeviceId = deviceId,
                    Value = phElement.GetDouble(),
                    Metadata = metadata,
                    Timestamp = timestamp
                };
                context.SensorPh.Add(ph);
            }

            // Temperature
            if (root.TryGetProperty("temperature", out var tempElement) ||
                root.TryGetProperty("temp", out tempElement))
            {
                var temp = new SensorTemp
                {
                    DeviceId = deviceId,
                    Value = tempElement.GetDouble(),
                    Metadata = metadata,
                    Timestamp = timestamp
                };
                context.SensorTemp.Add(temp);
            }

            // Weight
            if (root.TryGetProperty("weight", out var weightElement))
            {
                var weight = new SensorWeight
                {
                    DeviceId = deviceId,
                    Value = weightElement.GetDouble(),
                    Metadata = metadata,
                    Timestamp = timestamp
                };
                context.SensorWeight.Add(weight);
            }

            // Outside
            if (root.TryGetProperty("outside", out var outsideElement))
            {
                var outside = new SensorOutside
                {
                    DeviceId = deviceId,
                    Value = outsideElement.GetDouble(),
                    Metadata = metadata,
                    Timestamp = timestamp
                };
                context.SensorOutside.Add(outside);
            }

            await context.SaveChangesAsync(cancellationToken);

            // Broadcast to SignalR clients
            await _hubContext.Clients.All.SendAsync(
                "ReceiveSensorUpdate",
                new
                {
                    deviceId,
                    data = messageBody,
                    timestamp
                },
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing event data");
        }
    }

    private Task ProcessErrorHandler(ProcessErrorEventArgs args)
    {
        _logger.LogError(args.Exception, $"Error on partition {args.PartitionId}");
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("🛑 Stopping IoT Hub Listener...");
        
        if (_processor != null)
        {
            await _processor.StopProcessingAsync(cancellationToken);
            _processor.ProcessEventAsync -= ProcessEventHandler;
            _processor.ProcessErrorAsync -= ProcessErrorHandler;
        }

        await base.StopAsync(cancellationToken);
    }
}

