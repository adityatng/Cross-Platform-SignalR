using Microsoft.AspNetCore.SignalR;
using RealtimeNet9.Data;
using Microsoft.EntityFrameworkCore;
using RealtimeNet9.Models;

public class KanbanHub : Hub
{
    private readonly AppDbContext _db;

    public KanbanHub(AppDbContext db)
    {
        _db = db;
    }

    // Retrieve all Kanban cards from the database
    public async Task<List<KanbanCard>> GetCards()
        => await _db.KanbanCards.ToListAsync();

    // Add a new Kanban card to a specific column and notify all clients
    public async Task AddCard(string columnId, string text)
    {
        var card = new KanbanCard
        {
            ColumnId = columnId,
            Text = text
        };

        _db.KanbanCards.Add(card);
        await _db.SaveChangesAsync();

        await Clients.All.SendAsync("CardAdded", card);
    }

    // Move an existing Kanban card to a different column
    public async Task MoveCard(int cardId, string columnId)
    {
        var card = await _db.KanbanCards.FindAsync(cardId);
        if (card == null) return;

        card.ColumnId = columnId;
        await _db.SaveChangesAsync();

        await Clients.All.SendAsync("CardMoved", new
        {
            cardId,
            columnId
        });
    }

    // Update the text/content of an existing Kanban card
    public async Task UpdateCard(int id, string text)
    {
        var card = await _db.KanbanCards.FindAsync(id);
        if (card == null) return;

        card.Text = text;
        await _db.SaveChangesAsync();

        await Clients.All.SendAsync("CardUpdated", card);
    }

    // Delete a Kanban card and notify all clients
    public async Task DeleteCard(int id)
    {
        var card = await _db.KanbanCards.FindAsync(id);
        if (card == null) return;

        _db.KanbanCards.Remove(card);
        await _db.SaveChangesAsync();

        await Clients.All.SendAsync("CardDeleted", id);
    }
}