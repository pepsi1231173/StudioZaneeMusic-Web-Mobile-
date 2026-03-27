// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.
#nullable disable

using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using DuAnBai3.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging;

namespace DuAnBai3.Areas.Identity.Pages.Account
{
    public class LogoutModel : PageModel
    {
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly ILogger<LogoutModel> _logger;

        public LogoutModel(SignInManager<ApplicationUser> signInManager, ILogger<LogoutModel> logger)
        {
            _signInManager = signInManager;
            _logger = logger;
        }

        public async Task<IActionResult> OnPost(string returnUrl = null)
        {
            var isAdmin = User.IsInRole("admin");
            var isCashier = User.IsInRole("cashier");

            await _signInManager.SignOutAsync();
            _logger.LogInformation("User logged out.");

            if (isAdmin)
            {
                return RedirectToAction("Dashboard", "Homepage", new { area = "Admin" });
            }
            else if (isCashier)
            {
                return RedirectToAction("Index", "Dashboard", new { area = "Cashier" });
            }

            return RedirectToPage("/Index", new { area = "" });
        }

    }
}
