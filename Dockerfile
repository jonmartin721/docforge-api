FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
RUN apt-get update && apt-get install -y \
    curl \
    libgconf-2-4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgdk-pixbuf2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libnss3-dev \
    libxss-dev \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["DocumentGenerator.API/DocumentGenerator.API.csproj", "DocumentGenerator.API/"]
COPY ["DocumentGenerator.Core/DocumentGenerator.Core.csproj", "DocumentGenerator.Core/"]
COPY ["DocumentGenerator.Infrastructure/DocumentGenerator.Infrastructure.csproj", "DocumentGenerator.Infrastructure/"]
RUN dotnet restore "DocumentGenerator.API/DocumentGenerator.API.csproj"
COPY . .
WORKDIR "/src/DocumentGenerator.API"
RUN dotnet build "DocumentGenerator.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "DocumentGenerator.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DocumentGenerator.API.dll"]
