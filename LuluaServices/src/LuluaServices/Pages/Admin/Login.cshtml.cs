using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using LuluaServices.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;

namespace LuluaServices.Pages.Admin;

[EnableRateLimiting("forms")]
public class LoginModel(IOptions<AdminOptions> options, ILogger<LoginModel> logger) : PageModel
{
    private static readonly PasswordHasher<AdminOptions> Hasher = new();

    [BindProperty, Required(ErrorMessage = "اكتب اسم المستخدم")]
    public string Username { get; set; } = "";

    [BindProperty, Required(ErrorMessage = "اكتب كلمة المرور"), DataType(DataType.Password)]
    public string Password { get; set; } = "";

    public bool NotConfigured => string.IsNullOrWhiteSpace(options.Value.PasswordHash);

    public IActionResult OnGet()
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToPage("/Admin/Index");
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(string? returnUrl)
    {
        if (NotConfigured || !ModelState.IsValid) return Page();

        var admin = options.Value;
        var userOk = CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(Username.Trim().ToLowerInvariant()),
            Encoding.UTF8.GetBytes(admin.Username.ToLowerInvariant()));
        // Always run the hash check so a wrong username takes as long as a wrong password.
        var passOk = Hasher.VerifyHashedPassword(admin, admin.PasswordHash, Password) != PasswordVerificationResult.Failed;

        if (!userOk || !passOk)
        {
            logger.LogWarning("Failed dashboard login from {Ip}", HttpContext.Connection.RemoteIpAddress);
            ModelState.AddModelError(string.Empty, "اسم المستخدم أو كلمة المرور غير صحيحة");
            return Page();
        }

        var identity = new ClaimsIdentity(new[] { new Claim(ClaimTypes.Name, admin.Username) },
            CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(identity));

        return Url.IsLocalUrl(returnUrl) && returnUrl.StartsWith("/admin", StringComparison.OrdinalIgnoreCase)
            ? LocalRedirect(returnUrl)
            : RedirectToPage("/Admin/Index");
    }
}
