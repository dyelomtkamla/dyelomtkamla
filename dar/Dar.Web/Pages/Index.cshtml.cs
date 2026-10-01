using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;
using Dar.Web.Content;
using Dar.Web.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace Dar.Web.Pages;

[EnableRateLimiting("waitlist")]
public partial class IndexModel(DarDbContext db) : PageModel
{
    public SiteText T { get; private set; } = SiteText.Ar;

    [BindProperty] public JoinForm Form { get; set; } = new();

    /// <summary>"joined", "exists" or "invalid", shown above the form.</summary>
    public string? Status { get; private set; }

    public void OnGet(string? s)
    {
        T = SiteText.For(Request);
        Status = s is "joined" or "exists" ? s : null;
    }

    public async Task<IActionResult> OnPostAsync()
    {
        T = SiteText.For(Request);
        var contact = Normalize(Form.Contact);

        if (!ModelState.IsValid || contact is null
            || !T.Countries.Any(c => c.Value == Form.Country)
            || !T.Roles.Any(r => r.Value == Form.Role))
        {
            Status = "invalid";
            return Page();
        }

        var status = "joined";
        if (await db.Waitlist.AnyAsync(x => x.Contact == contact))
        {
            status = "exists";
        }
        else
        {
            db.Waitlist.Add(new WaitlistEntry
            {
                Name = Form.Name.Trim(),
                Contact = contact,
                Country = Form.Country,
                Role = Form.Role,
                Locale = T.Lang,
            });
            await db.SaveChangesAsync();
        }

        return Redirect($"{T.Home}?s={status}#join");
    }

    /// <summary>Lower-cases emails and strips phone numbers to digits; null when neither.</summary>
    static string? Normalize(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        raw = raw.Trim();
        if (raw.Contains('@'))
            return EmailRe().IsMatch(raw) ? raw.ToLowerInvariant() : null;
        var digits = new string(raw.Where(char.IsAsciiDigit).ToArray());
        return PhoneRe().IsMatch(raw) && digits.Length is >= 8 and <= 15 ? digits : null;
    }

    [GeneratedRegex(@"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$")] private static partial Regex EmailRe();
    [GeneratedRegex(@"^\+?[\d\s\-()]+$")] private static partial Regex PhoneRe();

    public class JoinForm
    {
        [Required, StringLength(80, MinimumLength = 2)] public string Name { get; set; } = "";
        [Required, StringLength(120)] public string Contact { get; set; } = "";
        [Required] public string Country { get; set; } = "SA";
        [Required] public string Role { get; set; } = "family";
    }
}
