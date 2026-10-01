using System.Net;
using LuluaServices.Data;
using LuluaServices.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace LuluaServices.Tests;

public class BookingAndAdminTests(AppFactory factory) : IClassFixture<AppFactory>
{
    [Fact]
    public async Task Valid_booking_is_saved_and_customer_sees_reference_number()
    {
        var client = factory.Browser();
        var res = await PostBooking(client, "pools", name: "عميل المسبح", phone: "0555000111");

        Assert.Equal(HttpStatusCode.Redirect, res.StatusCode);
        Assert.Equal("/book/thanks", res.Headers.Location!.OriginalString);

        var saved = await Db(db => db.Bookings.SingleAsync(b => b.Name == "عميل المسبح"));
        Assert.Equal("pools", saved.SectionSlug);
        Assert.Equal(BookingStatus.New, saved.Status);

        var thanks = await client.GetStringAsync("/book/thanks");
        Assert.Contains($"#{saved.Id}", thanks);
        Assert.Contains("خدمات المسابح", thanks);
        Assert.Contains("wa.me/966511111111", thanks);
    }

    [Fact]
    public async Task Invalid_booking_shows_arabic_errors_and_saves_nothing()
    {
        var before = await Db(db => db.Bookings.CountAsync());
        var res = await PostBooking(factory.Browser(), "cleaning", name: "", phone: "abc");

        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        var html = await res.Content.ReadAsStringAsync();
        Assert.Contains("فضلاً اكتب اسمك", html);
        Assert.Contains("رقم الجوال غير صحيح", html);
        Assert.Equal(before, await Db(db => db.Bookings.CountAsync()));
    }

    [Fact]
    public async Task Unknown_department_is_rejected()
    {
        var res = await PostBooking(factory.Browser(), "not-a-section", name: "اختبار قسم");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        Assert.Contains("فضلاً اختر قسماً صحيحاً", await res.Content.ReadAsStringAsync());
        Assert.False(await Db(db => db.Bookings.AnyAsync(b => b.Name == "اختبار قسم")));
    }

    [Fact]
    public async Task Honeypot_submission_is_silently_dropped()
    {
        var res = await PostBooking(factory.Browser(), "cleaning", name: "روبوت", website: "http://spam.example");
        Assert.Equal(HttpStatusCode.Redirect, res.StatusCode);
        Assert.False(await Db(db => db.Bookings.AnyAsync(b => b.Name == "روبوت")));
    }

    [Fact]
    public async Task Booking_without_antiforgery_token_is_refused()
    {
        var res = await factory.Browser().PostAsync("/book", new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["Input.Name"] = "بدون رمز", ["Input.Phone"] = "0555000222", ["Input.Section"] = "cleaning", ["Input.Area"] = "الحي",
        }));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task Dashboard_requires_login()
    {
        var res = await factory.Browser().GetAsync("/admin");
        Assert.Equal(HttpStatusCode.Redirect, res.StatusCode);
        Assert.StartsWith("http://localhost/admin/login", res.Headers.Location!.ToString());
    }

    [Fact]
    public async Task Wrong_password_is_rejected()
    {
        var client = factory.Browser();
        var res = await Login(client, "wrong-password");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        Assert.Contains("اسم المستخدم أو كلمة المرور غير صحيحة", await res.Content.ReadAsStringAsync());
        Assert.Equal(HttpStatusCode.Redirect, (await client.GetAsync("/admin")).StatusCode);
    }

    [Fact]
    public async Task Admin_can_list_update_export_and_delete_bookings()
    {
        await PostBooking(factory.Browser(), "insulation", name: "=HYPERLINK(\"x\")", phone: "0555000333", area: "حي الياسمين");
        var booking = await Db(db => db.Bookings.SingleAsync(b => b.Phone == "0555000333"));

        var client = factory.Browser();
        Assert.Equal(HttpStatusCode.Redirect, (await Login(client, AppFactory.AdminPassword)).StatusCode);

        var list = await client.GetStringAsync("/admin?section=insulation");
        Assert.Contains($"#{booking.Id}", list);
        Assert.Contains("noindex", list);

        var update = await client.PostAsync($"/admin?handler=Update&id={booking.Id}&section=insulation", new FormUrlEncodedContent(
            new Dictionary<string, string>
            {
                ["newStatus"] = nameof(BookingStatus.Confirmed),
                ["adminNotes"] = "الموعد الساعة 5",
                ["__RequestVerificationToken"] = AppFactory.Token(list),
            }));
        Assert.Equal(HttpStatusCode.Redirect, update.StatusCode);
        // The filter the admin was looking at is kept after saving.
        Assert.True(update.Headers.Location!.OriginalString.Contains("section=insulation"), update.Headers.Location.OriginalString);
        var updated = await Db(db => db.Bookings.AsNoTracking().SingleAsync(b => b.Id == booking.Id));
        Assert.Equal(BookingStatus.Confirmed, updated.Status);
        Assert.Equal("الموعد الساعة 5", updated.AdminNotes);

        var csv = await client.GetAsync("/admin?handler=Export&section=insulation");
        var bytes = await csv.Content.ReadAsByteArrayAsync();
        Assert.Equal(new byte[] { 0xEF, 0xBB, 0xBF }, bytes[..3]);
        var text = System.Text.Encoding.UTF8.GetString(bytes);
        Assert.Contains("\"'=HYPERLINK(\"\"x\"\")\"", text);
        Assert.Contains("مؤكد", text);

        var delete = await client.PostAsync($"/admin?handler=Delete&id={booking.Id}", new FormUrlEncodedContent(
            new Dictionary<string, string> { ["__RequestVerificationToken"] = AppFactory.Token(list) }));
        Assert.Equal(HttpStatusCode.Redirect, delete.StatusCode);
        Assert.False(await Db(db => db.Bookings.AnyAsync(b => b.Id == booking.Id)));
    }

    private async Task<HttpResponseMessage> PostBooking(HttpClient client, string section, string name = "عميل",
        string phone = "0555000999", string area = "حي النرجس", string website = "")
    {
        var page = await client.GetStringAsync("/book");
        return await client.PostAsync("/book", new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["Input.Name"] = name,
            ["Input.Phone"] = phone,
            ["Input.Section"] = section,
            ["Input.Area"] = area,
            ["Input.Notes"] = "ملاحظة",
            ["Input.Website"] = website,
            ["__RequestVerificationToken"] = AppFactory.Token(page),
        }));
    }

    private static async Task<HttpResponseMessage> Login(HttpClient client, string password)
    {
        var page = await client.GetStringAsync("/admin/login");
        return await client.PostAsync("/admin/login", new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["Username"] = "admin",
            ["Password"] = password,
            ["__RequestVerificationToken"] = AppFactory.Token(page),
        }));
    }

    private async Task<T> Db<T>(Func<AppDbContext, Task<T>> query)
    {
        using var scope = factory.Services.CreateScope();
        return await query(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }
}

public class RateLimitTests(StrictRateLimitFactory factory) : IClassFixture<StrictRateLimitFactory>
{
    [Fact]
    public async Task Repeated_form_posts_are_throttled()
    {
        var client = factory.Browser();
        var page = await client.GetStringAsync("/book");
        HttpResponseMessage last = null!;
        for (var i = 0; i < 3; i++)
        {
            last = await client.PostAsync("/book", new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["Input.Name"] = "", ["__RequestVerificationToken"] = AppFactory.Token(page),
            }));
        }
        Assert.Equal(HttpStatusCode.TooManyRequests, last.StatusCode);
        // Viewing pages is never throttled.
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/book")).StatusCode);
    }
}
