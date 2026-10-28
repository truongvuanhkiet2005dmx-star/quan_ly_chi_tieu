using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend_Nhom6_QuanLyChiTieu.Migrations
{
    /// <inheritdoc />
    public partial class AmountLongSupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // SQLite stores the Amount value with INTEGER affinity. Its storage format does
            // not require a table rebuild when the CLR model changes from int to long.
            migrationBuilder.Sql("SELECT 1;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // SQLite INTEGER affinity is compatible with both int and long. No schema
            // rebuild is needed when reversing the CLR-side type metadata.
            migrationBuilder.Sql("SELECT 1;");
        }
    }
}
