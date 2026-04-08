using Microsoft.EntityFrameworkCore;
using RealtimeNet9.Models;

namespace RealtimeNet9.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    public DbSet<KanbanCard> KanbanCards => Set<KanbanCard>();
    public DbSet<Item> Items => Set<Item>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<Document> Documents => Set<Document>();
}