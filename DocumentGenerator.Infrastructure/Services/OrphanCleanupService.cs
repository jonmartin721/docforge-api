using DocumentGenerator.Core.Settings;
using DocumentGenerator.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace DocumentGenerator.Infrastructure.Services
{
    /// <summary>
    /// Background service that periodically cleans up orphaned PDF files
    /// that exist on disk but have no corresponding database record.
    /// </summary>
    public class OrphanCleanupService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<OrphanCleanupService> _logger;
        private readonly string _storagePath;
        private static readonly TimeSpan CleanupInterval = TimeSpan.FromHours(24);

        public OrphanCleanupService(
            IServiceScopeFactory scopeFactory,
            ILogger<OrphanCleanupService> logger,
            IOptions<StorageSettings> storageSettings)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;

            var documentsPath = storageSettings.Value.DocumentsPath;
            _storagePath = Path.IsPathRooted(documentsPath)
                ? documentsPath
                : Path.Combine(Directory.GetCurrentDirectory(), documentsPath);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Orphan cleanup service started");

            // Initial delay before first cleanup
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CleanupOrphanedFilesAsync(stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    _logger.LogError(ex, "Error during orphan file cleanup");
                }

                await Task.Delay(CleanupInterval, stoppingToken);
            }
        }

        private async Task CleanupOrphanedFilesAsync(CancellationToken cancellationToken)
        {
            if (!Directory.Exists(_storagePath))
            {
                _logger.LogDebug("Storage directory does not exist, skipping cleanup");
                return;
            }

            var files = Directory.GetFiles(_storagePath, "*.pdf");
            if (files.Length == 0)
            {
                _logger.LogDebug("No PDF files found in storage, skipping cleanup");
                return;
            }

            _logger.LogInformation("Starting orphan file cleanup, checking {Count} files", files.Length);

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var storedPaths = await context.Documents
                .Select(d => d.StoragePath)
                .ToListAsync(cancellationToken);

            var storedPathsSet = new HashSet<string>(storedPaths, StringComparer.OrdinalIgnoreCase);

            var orphanedCount = 0;
            foreach (var file in files)
            {
                if (cancellationToken.IsCancellationRequested) break;

                if (!storedPathsSet.Contains(file))
                {
                    try
                    {
                        File.Delete(file);
                        orphanedCount++;
                        _logger.LogDebug("Deleted orphaned file: {FileName}", Path.GetFileName(file));
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to delete orphaned file: {FileName}", Path.GetFileName(file));
                    }
                }
            }

            if (orphanedCount > 0)
            {
                _logger.LogInformation("Cleaned up {Count} orphaned files", orphanedCount);
            }
            else
            {
                _logger.LogDebug("No orphaned files found");
            }
        }
    }
}
