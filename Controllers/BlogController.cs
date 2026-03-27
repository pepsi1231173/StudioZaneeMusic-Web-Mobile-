using Microsoft.AspNetCore.Mvc;

public class BlogController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Tin tức";
        return View();
    }
}
