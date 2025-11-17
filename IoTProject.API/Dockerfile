# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["IoTProject.API/IoTProject.API.csproj", "IoTProject.API/"]
RUN dotnet restore "IoTProject.API/IoTProject.API.csproj"

# Copy everything else and build
COPY . .
WORKDIR "/src/IoTProject.API"
RUN dotnet build "IoTProject.API.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "IoTProject.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Copy published app
COPY --from=publish /app/publish .

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "IoTProject.API.dll"]

