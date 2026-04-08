using Microsoft.AspNetCore.SignalR;
using RealtimeNet9.Data;
using Microsoft.EntityFrameworkCore;
using RealtimeNet9.Models;

public class EditorHub : Hub
{
    private readonly AppDbContext _db;

    public EditorHub(AppDbContext db)
    {
        _db = db;
    }

    // Load a document by name; create a new document if it does not exist
    public async Task<string> LoadDocument(string name)
    {
        var doc = await _db.Documents.FirstOrDefaultAsync(d => d.Name == name);
        if (doc == null)
        {
            doc = new Document { Name = name, Content = string.Empty };
            _db.Documents.Add(doc);
            await _db.SaveChangesAsync();
        }
        return doc.Content;
    }

    // Update document content and broadcast changes to other connected clients
    public async Task SendUpdate(string name, string newText)
    {
        var doc = await _db.Documents.FirstOrDefaultAsync(d => d.Name == name);
        if (doc == null)
        {
            doc = new Document { Name = name, Content = newText };
            _db.Documents.Add(doc);
        }
        else
        {
            doc.Content = newText;
        }

        await _db.SaveChangesAsync();

        // Notify other clients about the updated content
        await Clients.Others.SendAsync("ReceiveUpdate", newText);
    }
}