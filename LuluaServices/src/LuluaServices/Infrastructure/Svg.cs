using Microsoft.AspNetCore.Html;

namespace LuluaServices.Infrastructure;

/// <summary>Inline stroke icons (24x24) used across the site.</summary>
public static class Svg
{
    private static readonly Dictionary<string, string> Paths = new()
    {
        ["pest"] = "<path d=\"M12 8a3 3 0 0 1 3 3v4a3 3 0 0 1-6 0v-4a3 3 0 0 1 3-3z\"/><path d=\"M10 6.5 8.5 4M14 6.5 15.5 4M9 11H5M15 11h4M9 15H5.5M15 15h3.5M10 19l-2 2M14 19l2 2M12 8v10\"/>",
        ["clean"] = "<path d=\"M9 3h5v4H9z\"/><path d=\"M8 7h7l1 4v9a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1v-9z\"/><path d=\"M14 3h3l2 2M19 11l1-1M19 14h2M19 17l1 1\"/>",
        ["repair"] = "<path d=\"M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-2.6 2.6-2.4-.6-.6-2.4z\"/>",
        ["shield"] = "<path d=\"M12 3 4 6v6c0 4.5 3.4 8.2 8 9 4.6-.8 8-4.5 8-9V6z\"/><path d=\"M8 12h8M8 15.5h8M8 8.5h8\"/>",
        ["truck"] = "<path d=\"M2 6h12v10H2zM14 9h4l3 3.5V16h-7z\"/><circle cx=\"6\" cy=\"17.5\" r=\"1.8\"/><circle cx=\"17\" cy=\"17.5\" r=\"1.8\"/>",
        ["pool"] = "<path d=\"M2 17c1.5 1.3 3 1.3 4.5 0s3-1.3 4.5 0 3 1.3 4.5 0 3-1.3 4.5 0M2 21c1.5 1.3 3 1.3 4.5 0s3-1.3 4.5 0 3 1.3 4.5 0 3-1.3 4.5 0\"/><path d=\"M8 14V5a2 2 0 0 1 4 0M16 14V5a2 2 0 0 0-4 0M8 8h8M8 11h8\"/>",
        ["build"] = "<path d=\"M3 21h18M5 21V9l7-5 7 5v12\"/><path d=\"M9 21v-6h6v6M9 11h.01M15 11h.01\"/>",
        ["paint"] = "<path d=\"M4 4h13v5H4z\"/><path d=\"M17 6.5h3V12h-8v3\"/><path d=\"M10.5 15h3v6h-3z\"/>",
        ["check"] = "<path d=\"m5 12.5 4.5 4.5L19 7.5\"/>",
        ["home"] = "<path d=\"M3 11 12 4l9 7\"/><path d=\"M5 10v10h14V10\"/>",
        ["grid"] = "<path d=\"M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z\"/>",
        ["calendar"] = "<path d=\"M4 6h16v14H4zM4 10h16M8 3v5M16 3v5\"/>",
        ["phone"] = "<path d=\"M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z\"/>",
        ["back"] = "<path d=\"m9 6 6 6-6 6\"/>",
        ["clock"] = "<circle cx=\"12\" cy=\"12\" r=\"9\"/><path d=\"M12 7v5l3 2\"/>",
        ["star"] = "<path d=\"m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z\"/>",
        ["badge"] = "<circle cx=\"12\" cy=\"9\" r=\"6\"/><path d=\"m8.5 14-1.5 7 5-3 5 3-1.5-7\"/>",
        ["tag"] = "<path d=\"M3 12V4h8l10 10-8 8z\"/><circle cx=\"7.5\" cy=\"8\" r=\"1.5\"/>",
        ["install"] = "<path d=\"M12 3v12M7 10l5 5 5-5M5 21h14\"/>"
    };

    public static IHtmlContent Icon(string name, string cls = "ic") =>
        new HtmlString($"<svg class=\"{cls}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\" aria-hidden=\"true\">{Paths[name]}</svg>");

    public static IHtmlContent WhatsApp { get; } = new HtmlString("<svg viewBox=\"0 0 32 32\" aria-hidden=\"true\"><path fill=\"currentColor\" d=\"M16 3a13 13 0 0 0-11.2 19.6L3 29l6.6-1.7A13 13 0 1 0 16 3zm0 23.6a10.6 10.6 0 0 1-5.4-1.5l-.4-.2-3.9 1 1-3.8-.2-.4A10.6 10.6 0 1 1 16 26.6zm5.8-7.9c-.3-.2-1.9-.9-2.2-1s-.5-.2-.7.2-.8 1-1 1.2-.4.2-.7.1a8.7 8.7 0 0 1-4.3-3.8c-.3-.6.3-.5 1-1.7.1-.2 0-.4 0-.5l-1-2.4c-.3-.6-.5-.5-.7-.5h-.6a1.2 1.2 0 0 0-.9.4 3.6 3.6 0 0 0-1.1 2.7 6.3 6.3 0 0 0 1.3 3.3 14.4 14.4 0 0 0 5.5 4.9c2 .9 2.8.9 3.8.8a3.3 3.3 0 0 0 2.1-1.5 2.7 2.7 0 0 0 .2-1.5c-.1-.1-.3-.2-.7-.3z\"/></svg>");
}
