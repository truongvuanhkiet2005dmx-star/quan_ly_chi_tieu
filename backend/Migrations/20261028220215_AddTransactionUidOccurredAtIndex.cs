using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend_Nhom6_QuanLyChiTieu.Migrations
{
    /// <inheritdoc />
    public partial class AddTransactionUidOccurredAtIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_Transactions_Uid_OccurredAt",
                table: "Transactions",
                columns: new[] { "Uid", "OccurredAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Transactions_Uid_OccurredAt",
                table: "Transactions");
        }
    }
}
