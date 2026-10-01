namespace Dar.Web.Data;

public class WaitlistEntry
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Contact { get; set; } = "";
    public string Country { get; set; } = "";
    public string Role { get; set; } = "";
    public string Locale { get; set; } = "ar";
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
