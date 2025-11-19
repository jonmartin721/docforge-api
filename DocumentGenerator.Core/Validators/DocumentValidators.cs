using DocumentGenerator.Core.DTOs;
using FluentValidation;

namespace DocumentGenerator.Core.Validators
{
    public class GenerationRequestDtoValidator : AbstractValidator<GenerationRequestDto>
    {
        public GenerationRequestDtoValidator()
        {
            RuleFor(x => x.TemplateId)
                .NotEmpty().WithMessage("Template ID is required");

            RuleFor(x => x.Data)
                .NotNull().WithMessage("Data object is required");
        }
    }
}
