using Microsoft.AspNetCore.SignalR;
using RealtimeNet9.Data;
using RealtimeNet9.Models;
using Microsoft.EntityFrameworkCore;

namespace RealtimeNet9.Hubs;

public class ItemHub : Hub
{
    private readonly AppDbContext _db;

    public ItemHub(AppDbContext db) => _db = db;

    // Retrieve all items from the database
    public async Task<List<Item>> GetItems() 
        => await _db.Items.ToListAsync();

    // Add a new item and notify all connected clients
    public async Task AddItem(string name)
    {
        var item = new Item { Name = name };
        _db.Items.Add(item);
        await _db.SaveChangesAsync();

        await Clients.All.SendAsync("ItemAdded", item);
    }
}