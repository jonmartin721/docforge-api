using DocumentGenerator.Core.Interfaces;
using PuppeteerSharp;
using PuppeteerSharp.Media;

namespace DocumentGenerator.Infrastructure.Services
{
    public class PdfService : IPdfService
    {
        private bool _browserDownloaded = false;

        public async Task<byte[]> GeneratePdfAsync(string htmlContent)
        {
            if (!_browserDownloaded)
            {
                var browserFetcher = new BrowserFetcher();
                await browserFetcher.DownloadAsync();
                _browserDownloaded = true;
            }

            using var browser = await Puppeteer.LaunchAsync(new LaunchOptions
            {
                Headless = true,
                Args = new[] { "--no-sandbox" }
            });

            using var page = await browser.NewPageAsync();
            await page.SetContentAsync(htmlContent);
            
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
    }
}
