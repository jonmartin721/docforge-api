using System;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Validators;
using FluentAssertions;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class ValidatorTests
    {
        [Fact]
        public void RegisterDtoValidator_ShouldPass_WhenAllFieldsValid()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "validuser",
                Email = "test@example.com",
                Password = "Password123!"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeTrue();
        }

        [Fact]
        public void RegisterDtoValidator_ShouldFail_WhenUsernameEmpty()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "",
                Email = "test@example.com",
                Password = "Password123!"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.PropertyName == "Username");
        }

        [Fact]
        public void RegisterDtoValidator_ShouldFail_WhenUsernameTooShort()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "ab",
                Email = "test@example.com",
                Password = "Password123!"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.ErrorMessage.Contains("at least 3 characters"));
        }

        [Fact]
        public void RegisterDtoValidator_ShouldFail_WhenEmailInvalid()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "validuser",
                Email = "invalid-email",
                Password = "Password123!"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.PropertyName == "Email");
        }

        [Fact]
        public void RegisterDtoValidator_ShouldFail_WhenPasswordTooShort()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "validuser",
                Email = "test@example.com",
                Password = "Pass1!"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.ErrorMessage.Contains("at least 8 characters"));
        }

        [Fact]
        public void RegisterDtoValidator_ShouldFail_WhenPasswordMissingUppercase()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "validuser",
                Email = "test@example.com",
                Password = "password123!"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.ErrorMessage.Contains("uppercase"));
        }

        [Fact]
        public void RegisterDtoValidator_ShouldFail_WhenPasswordMissingLowercase()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "validuser",
                Email = "test@example.com",
                Password = "PASSWORD123!"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.ErrorMessage.Contains("lowercase"));
        }

        [Fact]
        public void RegisterDtoValidator_ShouldFail_WhenPasswordMissingDigit()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "validuser",
                Email = "test@example.com",
                Password = "Password!!"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.ErrorMessage.Contains("digit"));
        }

        [Fact]
        public void RegisterDtoValidator_ShouldFail_WhenPasswordMissingSpecialChar()
        {
            // Arrange
            var validator = new RegisterDtoValidator();
            var dto = new RegisterDto
            {
                Username = "validuser",
                Email = "test@example.com",
                Password = "Password123"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.ErrorMessage.Contains("special character"));
        }

        [Fact]
        public void LoginDtoValidator_ShouldPass_WhenAllFieldsValid()
        {
            // Arrange
            var validator = new LoginDtoValidator();
            var dto = new LoginDto
            {
                Username = "validuser",
                Password = "anypassword"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeTrue();
        }

        [Fact]
        public void LoginDtoValidator_ShouldFail_WhenUsernameEmpty()
        {
            // Arrange
            var validator = new LoginDtoValidator();
            var dto = new LoginDto
            {
                Username = "",
                Password = "password"
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
        }

        [Fact]
        public void LoginDtoValidator_ShouldFail_WhenPasswordEmpty()
        {
            // Arrange
            var validator = new LoginDtoValidator();
            var dto = new LoginDto
            {
                Username = "user",
                Password = ""
            };

            // Act
            var result = validator.Validate(dto);

            // Assert
            result.IsValid.Should().BeFalse();
        }

        // CreateTemplateDtoValidator Tests
        [Fact]
        public void CreateTemplateDtoValidator_ShouldPass_WhenValid()
        {
            var validator = new CreateTemplateDtoValidator();
            var dto = new CreateTemplateDto { Name = "Test", Content = "<h1>{{title}}</h1>" };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeTrue();
        }

        [Fact]
        public void CreateTemplateDtoValidator_ShouldFail_WhenNameEmpty()
        {
            var validator = new CreateTemplateDtoValidator();
            var dto = new CreateTemplateDto { Name = "", Content = "<h1>Test</h1>" };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.PropertyName == "Name");
        }

        [Fact]
        public void CreateTemplateDtoValidator_ShouldFail_WhenContentEmpty()
        {
            var validator = new CreateTemplateDtoValidator();
            var dto = new CreateTemplateDto { Name = "Test", Content = "" };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.PropertyName == "Content");
        }

        [Fact]
        public void CreateTemplateDtoValidator_ShouldFail_WhenInvalidHandlebars()
        {
            var validator = new CreateTemplateDtoValidator();
            var dto = new CreateTemplateDto { Name = "Test", Content = "{{#if unclosed}" };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.ErrorMessage.Contains("Invalid Handlebars"));
        }

        // UpdateTemplateDtoValidator Tests
        [Fact]
        public void UpdateTemplateDtoValidator_ShouldPass_WhenContentValid()
        {
            var validator = new UpdateTemplateDtoValidator();
            var dto = new UpdateTemplateDto { Content = "<h1>{{title}}</h1>" };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeTrue();
        }

        [Fact]
        public void UpdateTemplateDtoValidator_ShouldPass_WhenContentEmpty()
        {
            var validator = new UpdateTemplateDtoValidator();
            var dto = new UpdateTemplateDto { Name = "Updated Name" }; // Content not provided

            var result = validator.Validate(dto);

            result.IsValid.Should().BeTrue();
        }

        [Fact]
        public void UpdateTemplateDtoValidator_ShouldFail_WhenInvalidHandlebars()
        {
            var validator = new UpdateTemplateDtoValidator();
            var dto = new UpdateTemplateDto { Content = "{{#if unclosed}" };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeFalse();
        }

        // GenerationRequestDtoValidator Tests
        [Fact]
        public void GenerationRequestDtoValidator_ShouldPass_WhenValid()
        {
            var validator = new GenerationRequestDtoValidator();
            var dto = new GenerationRequestDto { TemplateId = Guid.NewGuid(), Data = new { Name = "Test" } };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeTrue();
        }

        [Fact]
        public void GenerationRequestDtoValidator_ShouldFail_WhenTemplateIdEmpty()
        {
            var validator = new GenerationRequestDtoValidator();
            var dto = new GenerationRequestDto { TemplateId = Guid.Empty, Data = new { } };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.PropertyName == "TemplateId");
        }

        [Fact]
        public void GenerationRequestDtoValidator_ShouldFail_WhenDataNull()
        {
            var validator = new GenerationRequestDtoValidator();
            var dto = new GenerationRequestDto { TemplateId = Guid.NewGuid(), Data = null! };

            var result = validator.Validate(dto);

            result.IsValid.Should().BeFalse();
            result.Errors.Should().Contain(e => e.PropertyName == "Data");
        }
    }
}
