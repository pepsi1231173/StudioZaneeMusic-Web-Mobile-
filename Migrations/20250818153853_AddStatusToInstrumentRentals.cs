using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DuAnBai3.Migrations
{
    /// <inheritdoc />
    public partial class AddStatusToInstrumentRentals : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "InstrumentRentals",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "InstrumentRentals");
        }
    }
}
