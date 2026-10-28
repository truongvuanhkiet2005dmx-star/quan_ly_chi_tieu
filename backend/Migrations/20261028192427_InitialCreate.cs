using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend_Nhom6_QuanLyChiTieu.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                CREATE TABLE IF NOT EXISTS ""Transactions"" (
                    ""Id"" INTEGER NOT NULL CONSTRAINT ""PK_Transactions"" PRIMARY KEY AUTOINCREMENT,
                    ""EventId"" TEXT NOT NULL,
                    ""Uid"" TEXT NOT NULL,
                    ""Amount"" INTEGER NOT NULL,
                    ""Type"" TEXT NOT NULL,
                    ""Source"" TEXT NOT NULL,
                    ""BankName"" TEXT NOT NULL,
                    ""PackageName"" TEXT NOT NULL,
                    ""OccurredAt"" TEXT NOT NULL,
                    ""CategoryName"" TEXT NOT NULL,
                    ""Note"" TEXT NOT NULL
                );
                CREATE UNIQUE INDEX IF NOT EXISTS ""IX_Transactions_Uid_EventId""
                ON ""Transactions"" (""Uid"", ""EventId"");
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Transactions");
        }
    }
}
