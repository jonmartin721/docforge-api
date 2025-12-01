using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using DocumentGenerator.API.Extensions;
using DocumentGenerator.API.Middleware;

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
        [ProducesResponseType(typeof(DocumentDto), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<DocumentDto>> Generate(GenerationRequestDto request)
        {
            var userId = this.GetUserId();
            var document = await _documentService.GenerateDocumentAsync(request, userId);
            return Ok(document);
        }

        [HttpPost("generate-batch")]
        [ProducesResponseType(typeof(BatchGenerationResultDto), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<BatchGenerationResultDto>> GenerateBatch(BatchGenerationRequestDto request)
        {
            var userId = this.GetUserId();
            var result = await _documentService.GenerateDocumentBatchAsync(request, userId);
            return Ok(result);
        }

        [HttpGet]
        [ProducesResponseType(typeof(PaginatedResult<DocumentDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<PaginatedResult<DocumentDto>>> GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var userId = this.GetUserId();
            return Ok(await _documentService.GetAllAsync(userId, page, pageSize));
        }

        [HttpGet("{id}")]
        [ProducesResponseType(typeof(DocumentDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<DocumentDto>> GetById(Guid id)
        {
            var userId = this.GetUserId();
            var document = await _documentService.GetByIdAsync(id, userId);
            if (document == null) return NotFound();
            return Ok(document);
        }

        [HttpGet("{id}/download")]
        [ProducesResponseType(typeof(FileContentResult), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Download(Guid id)
        {
            var userId = this.GetUserId();
            var fileData = await _documentService.GetDocumentFileAsync(id, userId);
            if (fileData == null) return NotFound();

            return File(fileData.Value.FileData, "application/pdf", fileData.Value.FileName);
        }

        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Delete(Guid id)
        {
            var userId = this.GetUserId();
            var result = await _documentService.DeleteAsync(id, userId);
            if (!result) return NotFound();
            return NoContent();
        }
    }
}
