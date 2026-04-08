using Microsoft.AspNetCore.SignalR;
using RealtimeNet9.Data;
using RealtimeNet9.Models;
using Microsoft.EntityFrameworkCore;

namespace RealtimeNet9.Hubs;

public class ChatHub : Hub
{
    private readonly AppDbContext _db;

    public ChatHub(AppDbContext db)
    {
        _db = db;
    }

    // Retrieve all chat messages ordered by timestamp
    public async Task<List<ChatMessage>> GetMessages()
    {
        return await _db.ChatMessages
            .OrderBy(m => m.Timestamp)
            .ToListAsync();
    }

    // Send a text message to all connected clients
    public async Task SendMessage(string user, string text, string clientId)
    {
        var msg = new ChatMessage
        {
            User = user,
            Text = text,
            ClientId = clientId,
            Timestamp = DateTime.UtcNow,
            Status = "sent",
            IsRead = false
        };

        _db.ChatMessages.Add(msg);
        await _db.SaveChangesAsync();

        await Clients.All.SendAsync("ReceiveMessage", msg);
    }

    // Send an image message to all connected clients
    public async Task SendImage(string user, string imageUrl, string clientId)
    {
        var msg = new ChatMessage
        {
            User = user,
            ImageUrl = imageUrl,
            ClientId = clientId,
            Timestamp = DateTime.UtcNow,
            Status = "sent",
            IsRead = false
        };

        _db.ChatMessages.Add(msg);
        await _db.SaveChangesAsync();

        await Clients.All.SendAsync("ReceiveMessage", msg);
    }

    // Update the text of an existing message
    public async Task UpdateMessage(int id, string newText)
    {
        var msg = await _db.ChatMessages.FindAsync(id);

        if (msg != null)
        {
            msg.Text = newText;

            await _db.SaveChangesAsync();

            await Clients.All.SendAsync("MessageUpdated", msg);
        }
    }

    // Delete a message by its ID
    public async Task DeleteMessage(int id)
    {
        var msg = await _db.ChatMessages.FindAsync(id);

        if (msg != null)
        {
            _db.ChatMessages.Remove(msg);
            await _db.SaveChangesAsync();

            await Clients.All.SendAsync("MessageDeleted", id);
        }
    }

    // Notify other clients when a user is typing
    public async Task Typing(string user, bool isTyping)
    {
        await Clients.Others.SendAsync("UserTyping", new
        {
            user,
            isTyping
        });
    }

    // Mark a message as read and update its status
    public async Task MarkAsRead(int messageId)
    {
        var msg = await _db.ChatMessages.FindAsync(messageId);

        if (msg != null)
        {
            msg.IsRead = true;
            msg.Status = "read";

            await _db.SaveChangesAsync();

            await Clients.All.SendAsync("MessageRead", messageId);
        }
    }

    // Handle user connection and notify all clients
    public override async Task OnConnectedAsync()
    {
        await Clients.All.SendAsync("UserOnline", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    // Handle user disconnection and notify all clients
    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await Clients.All.SendAsync("UserOffline", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }
}