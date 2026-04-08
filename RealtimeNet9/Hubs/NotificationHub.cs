using Microsoft.AspNetCore.SignalR;
using RealtimeNet9.Data;
using RealtimeNet9.Models;
using Microsoft.EntityFrameworkCore;

namespace RealtimeNet9.Hubs;

public class NotificationHub : Hub
{
    private readonly AppDbContext _db;

    public NotificationHub(AppDbContext db) => _db = db;

    // Retrieve all notifications ordered by timestamp
    public async Task<List<Notification>> GetNotifications() 
        => await _db.Notifications
            .OrderBy(n => n.Timestamp)
            .ToListAsync();

    // Send a new notification to all connected clients
    public async Task SendNotification(string text)
    {
        var note = new Notification
        {
            Text = text,
            Timestamp = DateTime.UtcNow
        };

        _db.Notifications.Add(note);
        await _db.SaveChangesAsync();

        await Clients.All.SendAsync("ReceiveNotification", note);
    }
}