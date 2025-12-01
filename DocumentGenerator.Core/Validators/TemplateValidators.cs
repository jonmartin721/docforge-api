using DocumentGenerator.Core.DTOs;
using FluentValidation;
using HandlebarsDotNet;

namespace DocumentGenerator.Core.Validators
{
    public class CreateTemplateDtoValidator : AbstractValidator<CreateTemplateDto>
    {
        public CreateTemplateDtoValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Template name is required");

            RuleFor(x => x.Content)
                .NotEmpty().WithMessage("Template content is required")
                .MaximumLength(1_000_000).WithMessage("Template content exceeds maximum size (1MB)")
                .Must(BeValidHandlebars).WithMessage("Invalid Handlebars syntax");
        }

        private static bool BeValidHandlebars(string content)
        {
            try
            {
                Handlebars.Compile(content);
                return true;
            }
            catch (HandlebarsException)
            {
                return false;
            }
        }
    }

    public class UpdateTemplateDtoValidator : AbstractValidator<UpdateTemplateDto>
    {
        public UpdateTemplateDtoValidator()
        {
            RuleFor(x => x.Content)
                .MaximumLength(1_000_000).WithMessage("Template content exceeds maximum size (1MB)")
                .When(x => !string.IsNullOrEmpty(x.Content));

            RuleFor(x => x.Content)
                .Must(BeValidHandlebars!)
                .When(x => !string.IsNullOrEmpty(x.Content))
                .WithMessage("Invalid Handlebars syntax");
        }

        private static bool BeValidHandlebars(string content)
        {
            try
            {
                Handlebars.Compile(content);
                return true;
            }
            catch (HandlebarsException)
            {
                return false;
            }
        }
    }
}
