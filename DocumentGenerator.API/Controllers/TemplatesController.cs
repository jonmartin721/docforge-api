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
    public class TemplatesController : ControllerBase
    {
        private readonly ITemplateService _templateService;

        public TemplatesController(ITemplateService templateService)
        {
            _templateService = templateService;
        }

        [HttpGet]
        [ProducesResponseType(typeof(PaginatedResult<TemplateDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<PaginatedResult<TemplateDto>>> GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            // Enforce pagination bounds
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var userId = this.GetUserId();
            return Ok(await _templateService.GetAllAsync(userId, page, pageSize));
        }

        [HttpGet("{id}")]
        [ProducesResponseType(typeof(TemplateDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<TemplateDto>> GetById(Guid id)
        {
            var userId = this.GetUserId();
            var template = await _templateService.GetByIdAsync(id, userId);
            if (template == null) return NotFound();
            return Ok(template);
        }

        [HttpPost]
        [ProducesResponseType(typeof(TemplateDto), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<TemplateDto>> Create(CreateTemplateDto createDto)
        {
            var userId = this.GetUserId();
            var template = await _templateService.CreateAsync(createDto, userId);
            return CreatedAtAction(nameof(GetById), new { id = template.Id }, template);
        }

        [HttpPut("{id}")]
        [ProducesResponseType(typeof(TemplateDto), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<TemplateDto>> Update(Guid id, UpdateTemplateDto updateDto)
        {
            var userId = this.GetUserId();
            var template = await _templateService.UpdateAsync(id, updateDto, userId);
            if (template == null) return NotFound();
            return Ok(template);
        }

        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Delete(Guid id)
        {
            var userId = this.GetUserId();
            var result = await _templateService.DeleteAsync(id, userId);
            if (!result) return NotFound();
            return NoContent();
        }
    }
}
