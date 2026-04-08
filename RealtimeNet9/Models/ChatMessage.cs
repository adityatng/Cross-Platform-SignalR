namespace RealtimeNet9.Models;

public class ChatMessage
{
    // Unique identifier for the message
    public int Id { get; set; }

    // Name or identifier of the user who sent the message
    public string User { get; set; } = string.Empty;

    // Text content of the message
    public string Text { get; set; } = string.Empty;

    // Optional URL for an image associated with the message
    public string? ImageUrl { get; set; }

    // Timestamp indicating when the message was created
    public DateTime Timestamp { get; set; }

    // Indicates whether the message has been read
    public bool IsRead { get; set; } = false;

    // Optional unique identifier for the client/device
    public string? ClientId { get; set; }

    // Current status of the message (e.g., sent, delivered, read)
    public string? Status { get; set; }
}