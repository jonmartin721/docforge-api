using System.Security.Claims;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using DocumentGenerator.API.Extensions;

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
        public async Task<ActionResult<IEnumerable<TemplateDto>>> GetAll()
        {
            return Ok(await _templateService.GetAllAsync());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TemplateDto>> GetById(Guid id)
        {
            var template = await _templateService.GetByIdAsync(id);
            if (template == null) return NotFound();
            return Ok(template);
        }

        [HttpPost]
        public async Task<ActionResult<TemplateDto>> Create(CreateTemplateDto createDto)
        {
            try
            {
                var userId = this.GetUserId();
                var template = await _templateService.CreateAsync(createDto, userId);
                return CreatedAtAction(nameof(GetById), new { id = template.Id }, template);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<TemplateDto>> Update(Guid id, UpdateTemplateDto updateDto)
        {
            try
            {
                var template = await _templateService.UpdateAsync(id, updateDto);
                if (template == null) return NotFound();
                return Ok(template);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            var result = await _templateService.DeleteAsync(id);
            if (!result) return NotFound();
            return NoContent();
        }
    }
}
