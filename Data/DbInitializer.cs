using Microsoft.AspNetCore.Identity;
using DuAnBai3.Models;

namespace DuAnBai3.Data
{
    public static class DbInitializer
    {
        public static async Task SeedRolesAndAdmin(IServiceProvider serviceProvider)
        {
            var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();
            var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();

            // Tạo các roles mặc định
            string[] roleNames = { SD.Role_Admin, SD.Role_Customer, SD.Role_Cashier };

            foreach (var roleName in roleNames)
            {
                if (!await roleManager.RoleExistsAsync(roleName))
                {
                    await roleManager.CreateAsync(new IdentityRole(roleName));
                }
            }

            // Tạo admin user mặc định
            var adminEmail = "Letran.230704@gmail.com";
            var adminUser = await userManager.FindByEmailAsync(adminEmail);

            if (adminUser == null)
            {
                adminUser = new ApplicationUser
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    FullName = "Administrator",
                    EmailConfirmed = true
                };

                var result = await userManager.CreateAsync(adminUser, "Letran123@");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(adminUser, SD.Role_Admin);
                }
            }
            else
            {
                if (!await userManager.IsInRoleAsync(adminUser, SD.Role_Admin))
                {
                    await userManager.AddToRoleAsync(adminUser, SD.Role_Admin);
                }
            }

            // (Tùy chọn) Tạo user cashier mặc định
            var cashierEmail = "cashier@example.com";
            var cashierUser = await userManager.FindByEmailAsync(cashierEmail);

            if (cashierUser == null)
            {
                cashierUser = new ApplicationUser
                {
                    UserName = cashierEmail,
                    Email = cashierEmail,
                    FullName = "Cashier Tester",
                    EmailConfirmed = true
                };

                var result = await userManager.CreateAsync(cashierUser, "Cashier123");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(cashierUser, SD.Role_Cashier);
                }
            }
            else
            {
                if (!await userManager.IsInRoleAsync(cashierUser, SD.Role_Cashier))
                {
                    await userManager.AddToRoleAsync(cashierUser, SD.Role_Cashier);
                }
            }
        }
    }
}
