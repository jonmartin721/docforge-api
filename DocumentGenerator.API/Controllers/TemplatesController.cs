using System.Security.Claims;
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
        [ProducesResponseType(typeof(IEnumerable<TemplateDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<TemplateDto>>> GetAll()
        {
            return Ok(await _templateService.GetAllAsync());
        }

        [HttpGet("{id}")]
        [ProducesResponseType(typeof(TemplateDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<TemplateDto>> GetById(Guid id)
        {
            var template = await _templateService.GetByIdAsync(id);
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
            var template = await _templateService.UpdateAsync(id, updateDto);
            if (template == null) return NotFound();
            return Ok(template);
        }

        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Delete(Guid id)
        {
            var result = await _templateService.DeleteAsync(id);
            if (!result) return NotFound();
            return NoContent();
        }
    }
}
