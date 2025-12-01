using DocumentGenerator.Core.DTOs;
using FluentAssertions;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class PaginatedResultTests
    {
        [Fact]
        public void TotalPages_ShouldCalculateCorrectly()
        {
            // Arrange & Act
            var result = new PaginatedResult<string>(new[] { "a", "b" }, 10, 1, 3);

            // Assert
            result.TotalPages.Should().Be(4); // ceil(10/3) = 4
        }

        [Fact]
        public void TotalPages_ShouldReturnZero_WhenPageSizeIsZero()
        {
            // Arrange & Act
            var result = new PaginatedResult<string>(Array.Empty<string>(), 0, 1, 0);

            // Assert
            result.TotalPages.Should().Be(0);
        }

        [Fact]
        public void HasPreviousPage_ShouldReturnFalse_WhenOnFirstPage()
        {
            // Arrange & Act
            var result = new PaginatedResult<string>(new[] { "a" }, 10, 1, 5);

            // Assert
            result.HasPreviousPage.Should().BeFalse();
        }

        [Fact]
        public void HasPreviousPage_ShouldReturnTrue_WhenNotOnFirstPage()
        {
            // Arrange & Act
            var result = new PaginatedResult<string>(new[] { "a" }, 10, 2, 5);

            // Assert
            result.HasPreviousPage.Should().BeTrue();
        }

        [Fact]
        public void HasNextPage_ShouldReturnTrue_WhenNotOnLastPage()
        {
            // Arrange & Act
            var result = new PaginatedResult<string>(new[] { "a" }, 10, 1, 5);

            // Assert
            result.HasNextPage.Should().BeTrue();
        }

        [Fact]
        public void HasNextPage_ShouldReturnFalse_WhenOnLastPage()
        {
            // Arrange & Act
            var result = new PaginatedResult<string>(new[] { "a" }, 10, 2, 5);

            // Assert
            result.HasNextPage.Should().BeFalse();
        }

        [Fact]
        public void Create_ShouldReturnPaginatedResult()
        {
            // Arrange
            var items = new[] { "item1", "item2" };

            // Act
            var result = PaginatedResult<string>.Create(items, 100, 1, 20);

            // Assert
            result.Should().NotBeNull();
            result.Items.Should().HaveCount(2);
            result.TotalCount.Should().Be(100);
            result.Page.Should().Be(1);
            result.PageSize.Should().Be(20);
        }

        [Fact]
        public void DefaultConstructor_ShouldInitializeWithDefaults()
        {
            // Act
            var result = new PaginatedResult<string>();

            // Assert
            result.Items.Should().BeEmpty();
            result.Page.Should().Be(0);
            result.PageSize.Should().Be(0);
            result.TotalCount.Should().Be(0);
        }
    }
}
