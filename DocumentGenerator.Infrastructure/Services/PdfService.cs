using DocumentGenerator.Core.Interfaces;
using PuppeteerSharp;
using PuppeteerSharp.Media;

namespace DocumentGenerator.Infrastructure.Services
{
    public class PdfService : IPdfService
    {
        private static readonly SemaphoreSlim _browserDownloadLock = new(1, 1);
        private static bool _browserDownloaded = false;
        private const int PdfGenerationTimeoutMs = 30000; // 30 seconds

        public async Task<byte[]> GeneratePdfAsync(string htmlContent)
        {
            try
            {
                await EnsureBrowserDownloadedAsync();

                using var browser = await Puppeteer.LaunchAsync(new LaunchOptions
                {
                    Headless = true,
                    Args = new[] { "--no-sandbox", "--disable-dev-shm-usage" }
                });

                using var page = await browser.NewPageAsync();
                await page.SetContentAsync(htmlContent, new NavigationOptions
                {
                    Timeout = PdfGenerationTimeoutMs,
                    WaitUntil = new[] { WaitUntilNavigation.Load }
                });

                return await page.PdfDataAsync(new PdfOptions
                {
                    Format = PaperFormat.A4,
                    PrintBackground = true,
                    MarginOptions = new MarginOptions
                    {
                        Top = "1cm",
                        Bottom = "1cm",
                        Left = "1cm",
                        Right = "1cm"
                    }
                });
            }
            catch (TimeoutException ex)
            {
                throw new InvalidOperationException("PDF generation timed out", ex);
            }
            catch (PuppeteerException ex)
            {
                throw new InvalidOperationException("PDF generation failed", ex);
            }
        }

        private static async Task EnsureBrowserDownloadedAsync()
        {
            if (_browserDownloaded) return;

            await _browserDownloadLock.WaitAsync();
            try
            {
                if (!_browserDownloaded)
                {
                    var browserFetcher = new BrowserFetcher();
                    await browserFetcher.DownloadAsync();
                    _browserDownloaded = true;
                }
            }
            finally
            {
                _browserDownloadLock.Release();
            }
        }
    }
}
