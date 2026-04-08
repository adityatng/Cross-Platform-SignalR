using Microsoft.EntityFrameworkCore;
using RealtimeNet9.Data;
using RealtimeNet9.Hubs;

var builder = WebApplication.CreateBuilder(args);

// CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite("Data Source=realtime9.db"));

// SignalR
builder.Services.AddSignalR();

var app = builder.Build();

// Ensure DB
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

// Middleware
app.UseCors();
app.UseDefaultFiles();
app.UseStaticFiles();

// Map Hubs
app.MapHub<KanbanHub>("/kanbanHub");
app.MapHub<ItemHub>("/itemHub");
app.MapHub<ChatHub>("/chatHub");
app.MapHub<NotificationHub>("/notificationHub");
app.MapHub<EditorHub>("/editorHub");

app.Run();