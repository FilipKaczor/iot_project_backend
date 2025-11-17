import axios from 'axios';
import * as signalR from '@microsoft/signalr';
import AsyncStorage from '@react-native-async-storage/async-storage';

// ⚠️ ZMIEŃ NA SWÓJ ADRES!
// Development - lokalny serwer
// export const API_BASE_URL = 'https://localhost:7000';
// export const SIGNALR_HUB_URL = 'https://localhost:7000/hubs/sensordata';

// Android emulator
export const API_BASE_URL = 'https://10.0.2.2:7000';
export const SIGNALR_HUB_URL = 'https://10.0.2.2:7000/hubs/sensordata';

// Fizyczne urządzenie (ustaw swoje lokalne IP)
// export const API_BASE_URL = 'https://192.168.1.100:7000';
// export const SIGNALR_HUB_URL = 'https://192.168.1.100:7000/hubs/sensordata';

// Azure (po deployment)
// export const API_BASE_URL = 'https://iot-project-api.azurewebsites.net';
// export const SIGNALR_HUB_URL = 'https://iot-project-api.azurewebsites.net/hubs/sensordata';

// Axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor - dodaj token do requestów
api.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Interceptor - obsługa błędów
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 || error.response?.status === 403) {
      // Token wygasł - wyloguj
      await AsyncStorage.removeItem('authToken');
      await AsyncStorage.removeItem('userData');
    }
    return Promise.reject(error);
  }
);

export default api;

// ============ API Functions ============

export const authAPI = {
  login: (email: string, password: string) =>
    api.post('/api/auth/login', { email, password }),
  
  register: (firstName: string, lastName: string, email: string, password: string) =>
    api.post('/api/auth/register', { firstName, lastName, email, password }),
};

export const sensorAPI = {
  getAllData: (limit = 10) =>
    api.get(`/api/sensordata/all?limit=${limit}`),
  
  getPhData: (limit = 10) =>
    api.get(`/api/sensordata/ph?limit=${limit}`),
  
  getTempData: (limit = 10) =>
    api.get(`/api/sensordata/temp?limit=${limit}`),
  
  getWeightData: (limit = 10) =>
    api.get(`/api/sensordata/weight?limit=${limit}`),
  
  getOutsideData: (limit = 10) =>
    api.get(`/api/sensordata/outside?limit=${limit}`),
  
  getStats: () =>
    api.get('/api/sensordata/stats'),
};

// ============ SignalR Connection ============

export const createSignalRConnection = async (): Promise<signalR.HubConnection | null> => {
  try {
    const token = await AsyncStorage.getItem('authToken');
    
    if (!token) {
      console.warn('No auth token found for SignalR connection');
      return null;
    }

    const connection = new signalR.HubConnectionBuilder()
      .withUrl(SIGNALR_HUB_URL, {
        accessTokenFactory: () => token,
        skipNegotiation: false,
        transport: signalR.HttpTransportType.WebSockets | signalR.HttpTransportType.LongPolling
      })
      .withAutomaticReconnect({
        nextRetryDelayInMilliseconds: retryContext => {
          // Exponential backoff: 0s, 2s, 10s, 30s
          if (retryContext.previousRetryCount === 0) return 0;
          if (retryContext.previousRetryCount === 1) return 2000;
          if (retryContext.previousRetryCount === 2) return 10000;
          return 30000;
        }
      })
      .configureLogging(signalR.LogLevel.Information)
      .build();

    // Event handlers
    connection.onreconnecting((error) => {
      console.log('SignalR reconnecting...', error?.message);
    });

    connection.onreconnected((connectionId) => {
      console.log('SignalR reconnected:', connectionId);
    });

    connection.onclose((error) => {
      console.log('SignalR connection closed:', error?.message);
    });

    return connection;
  } catch (error) {
    console.error('Error creating SignalR connection:', error);
    return null;
  }
};

export const startSignalRConnection = async (
  connection: signalR.HubConnection
): Promise<boolean> => {
  try {
    await connection.start();
    console.log('✅ SignalR connected');
    
    // Subscribe to updates
    await connection.invoke('SubscribeToUpdates');
    console.log('✅ Subscribed to sensor updates');
    
    return true;
  } catch (error) {
    console.error('❌ SignalR connection error:', error);
    return false;
  }
};

export const stopSignalRConnection = async (
  connection: signalR.HubConnection | null
): Promise<void> => {
  if (!connection) return;
  
  try {
    await connection.invoke('UnsubscribeFromUpdates');
    await connection.stop();
    console.log('SignalR connection stopped');
  } catch (error) {
    console.error('Error stopping SignalR connection:', error);
  }
};

