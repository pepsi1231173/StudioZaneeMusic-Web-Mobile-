using Microsoft.AspNetCore.Mvc;

public class HomePageController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}