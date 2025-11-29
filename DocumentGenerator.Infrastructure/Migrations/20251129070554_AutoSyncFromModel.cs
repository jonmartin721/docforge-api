using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DocumentGenerator.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AutoSyncFromModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_Documents_TemplateId",
                table: "Documents",
                column: "TemplateId");

            migrationBuilder.AddForeignKey(
                name: "FK_Documents_Templates_TemplateId",
                table: "Documents",
                column: "TemplateId",
                principalTable: "Templates",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Documents_Templates_TemplateId",
                table: "Documents");

            migrationBuilder.DropIndex(
                name: "IX_Documents_TemplateId",
                table: "Documents");
        }
    }
}
