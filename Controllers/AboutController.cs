using Microsoft.AspNetCore.Mvc;

public class AboutController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Giới thiệu";
        return View();
    }
}
