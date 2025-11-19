namespace DocumentGenerator.Core.Interfaces
{
    public interface IPdfService
    {
        Task<byte[]> GeneratePdfAsync(string htmlContent);
    }
}
