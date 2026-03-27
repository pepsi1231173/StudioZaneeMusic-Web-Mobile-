using DuAnBai3.Models;
using DuAnBai3.Hubs;
using DuAnBai3.Repositories;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using DuAnBai3.BackgroundServices;
using DuAnBai3.Services;
using Microsoft.AspNetCore.Http.Connections;

var builder = WebApplication.CreateBuilder(args);

// ✅ 1. Kết nối CSDL
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ✅ 2. Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 6;
    options.Password.RequireUppercase = false;
    options.Password.RequireLowercase = false;
    options.Password.RequireNonAlphanumeric = false;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders()
.AddDefaultUI();

// ✅ 3. Cookie riêng cho từng role
builder.Services.AddAuthentication()
    .AddCookie("AdminCookie", options =>
    {
        options.LoginPath = "/Admin/Account/Login";
        options.AccessDeniedPath = "/Admin/Account/AccessDenied";
    })
    .AddCookie("UserCookie", options =>
    {
        options.LoginPath = "/Identity/Account/Login";
        options.AccessDeniedPath = "/Identity/Account/AccessDenied";
    });

// ✅ 4. FIX: Ngăn SignalR / API bị redirect sang trang login
builder.Services.ConfigureApplicationCookie(options =>
{
    options.Events.OnRedirectToLogin = context =>
    {
        if (context.Request.Path.StartsWithSegments("/bookingHub") ||
            context.Request.Path.StartsWithSegments("/api"))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return Task.CompletedTask;
        }

        context.Response.Redirect(context.RedirectUri);
        return Task.CompletedTask;
    };

    options.Events.OnRedirectToAccessDenied = context =>
    {
        if (context.Request.Path.StartsWithSegments("/bookingHub") ||
            context.Request.Path.StartsWithSegments("/api"))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return Task.CompletedTask;
        }

        context.Response.Redirect(context.RedirectUri);
        return Task.CompletedTask;
    };
});

// ✅ 5. Session
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});
builder.Services.AddHttpContextAccessor();

// ✅ 6. Repository & Service
builder.Services.AddScoped<IProductRepository, EFProductRepository>();
builder.Services.AddScoped<ICategoryRepository, EFCategoryRepository>();
builder.Services.AddScoped<MaintenanceService>();

// ✅ 7. Background Services
builder.Services.AddHostedService<BookingCleanupService>();
builder.Services.AddHostedService<TimeBroadcastService>();
builder.Services.AddHostedService<BookingStatusUpdater>();
builder.Services.AddHostedService<BookingStatusService>();
builder.Services.AddHostedService<BookingMonitorService>();

// ✅ 8. Add MVC + SignalR + Swagger
builder.Services.AddRazorPages();
builder.Services.AddControllersWithViews();
builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ✅ 9. CORS cho Flutter
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials()
            .SetIsOriginAllowed(_ => true);
    });
});

var app = builder.Build();

// ✅ 10. Swagger cho Dev
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "DuAnBai3 API V1");
        options.RoutePrefix = "swagger";
    });
}
else
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

// ✅ Không ép HTTPS (Flutter đang dùng HTTP)
app.UseStaticFiles();
app.UseWebSockets();
app.UseRouting();

// ✅ 11. Cho phép CORS
app.UseCors("AllowFlutter");

// ✅ 12. Session + Auth
app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

// ✅ 13. Cho phép truy cập tự do vào /bookingHub mà không cần đăng nhập
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/bookingHub"))
    {
        // Không ép redirect login
        context.Items["AllowAnonymousHub"] = true;
    }
    await next();
});

// ✅ 14. Chặn customer vào Admin
app.Use(async (context, next) =>
{
    var path = context.Request.Path.Value;
    var role = context.Session.GetString("role");
    if (!string.IsNullOrEmpty(role) && role == "Customer" && path.StartsWith("/Admin"))
    {
        context.Response.Redirect("/Identity/AccessDenied");
        return;
    }
    await next();
});

// ✅ 15. Map Razor Pages & Controllers
app.MapRazorPages();
app.MapControllerRoute(
    name: "areas",
    pattern: "{area:exists}/{controller=Homepage}/{action=Dashboard}/{id?}");
app.MapControllerRoute(
    name: "areas2",
    pattern: "{area:exists}/{controller=Dashboard}/{action=Index}/{id?}");
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// ✅ 16. Seed role + admin
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    await DuAnBai3.Data.DbInitializer.SeedRolesAndAdmin(services);
}

// ✅ 17. Map SignalR Hub
app.MapHub<BookingHub>("/bookingHub", options =>
{
    options.Transports = HttpTransportType.WebSockets | HttpTransportType.LongPolling;
})
.RequireCors("AllowFlutter");

// ✅ Hub cho thuê nhạc cụ (Instrument)
app.MapHub<InstrumentHub>("/instrumentHub", options =>
{
    options.Transports = HttpTransportType.WebSockets | HttpTransportType.LongPolling;
})
.RequireCors("AllowFlutter");

app.Run();

