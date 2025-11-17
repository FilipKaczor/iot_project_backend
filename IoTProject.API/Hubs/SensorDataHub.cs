using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace IoTProject.API.Hubs;

[Authorize]
public class SensorDataHub : Hub
{
    private readonly ILogger<SensorDataHub> _logger;

    public SensorDataHub(ILogger<SensorDataHub> logger)
    {
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.Identity?.Name ?? "Anonymous";
        _logger.LogInformation($"Client connected: {Context.ConnectionId}, User: {userId}");
        
        await Clients.Caller.SendAsync("Connected", new
        {
            message = "Connected to IoT Project SignalR Hub",
            connectionId = Context.ConnectionId,
            timestamp = DateTime.UtcNow
        });

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.Identity?.Name ?? "Anonymous";
        _logger.LogInformation($"Client disconnected: {Context.ConnectionId}, User: {userId}");
        
        await base.OnDisconnectedAsync(exception);
    }

    public async Task SubscribeToUpdates()
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, "SensorUpdates");
        await Clients.Caller.SendAsync("Subscribed", new
        {
            message = "Subscribed to sensor updates",
            timestamp = DateTime.UtcNow
        });
        _logger.LogInformation($"Client {Context.ConnectionId} subscribed to updates");
    }

    public async Task UnsubscribeFromUpdates()
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, "SensorUpdates");
        await Clients.Caller.SendAsync("Unsubscribed", new
        {
            message = "Unsubscribed from sensor updates",
            timestamp = DateTime.UtcNow
        });
        _logger.LogInformation($"Client {Context.ConnectionId} unsubscribed from updates");
    }
}

