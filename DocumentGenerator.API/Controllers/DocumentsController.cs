using System.Security.Claims;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DocumentGenerator.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class DocumentsController : ControllerBase
    {
        private readonly IDocumentService _documentService;

        public DocumentsController(IDocumentService documentService)
        {
            _documentService = documentService;
        }

        [HttpPost("generate")]
        public async Task<ActionResult<DocumentDto>> Generate(GenerationRequestDto request)
        {
            try
            {
                var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
                var document = await _documentService.GenerateDocumentAsync(request, userId);
                return Ok(document);
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<DocumentDto>>> GetAll()
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            return Ok(await _documentService.GetAllAsync(userId));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<DocumentDto>> GetById(Guid id)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            var document = await _documentService.GetByIdAsync(id, userId);
            if (document == null) return NotFound();
            return Ok(document);
        }

        [HttpGet("{id}/download")]
        public async Task<IActionResult> Download(Guid id)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            try
            {
                var fileData = await _documentService.GetDocumentFileAsync(id, userId);
                if (fileData == null) return NotFound();

                return File(fileData.Value.FileData, "application/pdf", fileData.Value.FileName);
            }
            catch (FileNotFoundException)
            {
                return NotFound(new { message = "File not found on server" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            var result = await _documentService.DeleteAsync(id, userId);
            if (!result) return NotFound();
            return NoContent();
        }
    }
}
