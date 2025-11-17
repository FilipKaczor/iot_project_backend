using Microsoft.Azure.Devices;

namespace IoTProject.API.Services;

public class IoTHubService
{
    private readonly ServiceClient? _serviceClient;
    private readonly ILogger<IoTHubService> _logger;
    private readonly string? _connectionString;

    public IoTHubService(IConfiguration configuration, ILogger<IoTHubService> logger)
    {
        _logger = logger;
        _connectionString = configuration["AzureIoTHub:ConnectionString"];

        if (!string.IsNullOrEmpty(_connectionString) && !_connectionString.Contains("your-iot-hub"))
        {
            try
            {
                _serviceClient = ServiceClient.CreateFromConnectionString(_connectionString);
                _logger.LogInformation("✅ IoT Hub Service Client initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to initialize IoT Hub Service Client");
            }
        }
        else
        {
            _logger.LogWarning("⚠️  IoT Hub connection string not configured");
        }
    }

    public async Task<bool> SendCloudToDeviceMessageAsync(string deviceId, string message)
    {
        if (_serviceClient == null)
        {
            _logger.LogWarning("IoT Hub Service Client not initialized");
            return false;
        }

        try
        {
            var commandMessage = new Message(System.Text.Encoding.UTF8.GetBytes(message));
            await _serviceClient.SendAsync(deviceId, commandMessage);
            _logger.LogInformation($"Message sent to device {deviceId}");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending message to device {deviceId}");
            return false;
        }
    }

    public async Task<CloudToDeviceMethodResult?> InvokeDeviceMethodAsync(
        string deviceId, 
        string methodName, 
        string payload = "{}")
    {
        if (_serviceClient == null)
        {
            _logger.LogWarning("IoT Hub Service Client not initialized");
            return null;
        }

        try
        {
            var method = new CloudToDeviceMethod(methodName);
            method.SetPayloadJson(payload);
            
            var result = await _serviceClient.InvokeDeviceMethodAsync(deviceId, method);
            _logger.LogInformation($"Method {methodName} invoked on device {deviceId}, status: {result.Status}");
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error invoking method {methodName} on device {deviceId}");
            return null;
        }
    }
}

