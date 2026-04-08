<template>
  <div id="app">
    <h1>SignalR</h1>

    <!-- Kanban Board -->
    <section>
      <h2>Kanban Board</h2>
      <div class="board">
        <div class="column" v-for="col in columns" :key="col.id" @dragover.prevent @drop="() => onDrop(col.id)">
          <h3>{{ col.name }}</h3>

          <div class="card" v-for="card in getCards(col.id)" :key="card.id" draggable="true"
            @dragstart="() => onDragStart(card)">
            <div v-if="editCardId !== card.id">
              {{ card.text }}
              <br />
              <button @click="() => startEdit(card)">Edit</button>
              <button @click="() => deleteCard(card.id)">Delete</button>
            </div>

            <div v-else>
              <input v-model="editText" />
              <button @click="() => saveEdit(card)">Save</button>
              <button @click="cancelEdit">Cancel</button>
            </div>
          </div>

          <input v-model="newCard[col.id]" placeholder="New card" />
          <button @click="() => addCard(col.id)">Add</button>
        </div>
      </div>
    </section>

    <!-- Text Editor -->
    <section>
      <h2>Text Editor</h2>
      <textarea ref="textareaRef" v-model="content" @input="sendUpdate" rows="10" cols="60"></textarea>
    </section>

    <!-- Items -->
    <section>
      <h2>Items</h2>
      <input v-model="newItemName" placeholder="New item name" />
      <button @click="addItem">Add Item</button>
      <ul>
        <li v-for="item in items" :key="item.id">{{ item.id }}: {{ item.name }}</li>
      </ul>
    </section>

    <!-- Chat -->
    <section>
      <h2>Chat</h2>
      <input v-model="newMessage" @input="sendTyping" placeholder="Message" />
      <button @click="sendMessage">Send</button>

      <!-- Typing Indicator -->
      <div v-if="typingUsers.length" class="typing-indicator">
        {{ typingUsers.join(", ") }} is typing...
      </div>

      <ul class="chat-list">
        <li v-for="msg in messages" :key="msg.id">
          <template v-if="editMsgId !== msg.id">
            <strong>{{ msg.user }}:</strong> {{ msg.text }}
            <span v-if="msg.status === 'read'">✔️</span>
            <button v-if="msg.user === userName" @click="startEditMessage(msg)">Edit</button>
            <button v-if="msg.user === userName" @click="deleteMessage(msg.id)">Delete</button>
          </template>
          <template v-else>
            <input v-model="editMsgText" />
            <button @click="saveEditMessage(msg)">Save</button>
            <button @click="cancelEditMessage">Cancel</button>
          </template>
        </li>
      </ul>
    </section>

    <!-- Notifications -->
    <section>
      <h2>Notifications</h2>
      <button @click="sendNotification">Send Notification</button>
      <ul>
        <li v-for="note in notifications" :key="note.id">{{ note.text }}</li>
      </ul>
    </section>

  </div>
</template>

<script>
import { ref, reactive, onMounted } from "vue";
import * as signalR from "@microsoft/signalr";

export default {
  setup() {
    // --- Kanban ---
    const columns = [
      { id: "todo", name: "Todo" },
      { id: "progress", name: "In Progress" },
      { id: "done", name: "Done" },
    ];
    const cards = reactive([]);
    const draggedCard = ref(null);
    const newCard = reactive({ todo: "", progress: "", done: "" });
    const editCardId = ref(null);
    const editText = ref("");

    // --- Items ---
    const items = reactive([]);
    const newItemName = ref("");

    // --- Chat ---
    const messages = reactive([]);
    const newMessage = ref("");
    const typingUsers = reactive([]);
    const userName = `User_${Math.floor(Math.random() * 1000)}`;

    // --- Notifications ---
    const notifications = reactive([]);

    // --- Editor ---
    const content = ref("");
    const docName = "doc1";
    const textareaRef = ref(null);

    let kanbanHub, itemHub, chatHub, notificationHub, editorHub;
    let typingTimeout;

    const createHub = (url, events = {}) => {
      const hub = new signalR.HubConnectionBuilder()
        .withUrl(url, { withCredentials: true })
        .withAutomaticReconnect()
        .build();
      Object.entries(events).forEach(([event, callback]) => hub.on(event, callback));
      return hub;
    };

    // --- Kanban Methods ---
    const getCards = (columnId) => cards.filter((c) => c.columnId === columnId);
    const onDragStart = (card) => (draggedCard.value = card);
    const onDrop = async (columnId) => {
      if (!draggedCard.value) return;
      draggedCard.value.columnId = columnId;
      await kanbanHub.invoke("MoveCard", draggedCard.value.id, columnId);
      draggedCard.value = null;
    };
    const addCard = async (columnId) => {
      const text = newCard[columnId];
      if (!text) return;
      await kanbanHub.invoke("AddCard", columnId, text);
      newCard[columnId] = "";
    };
    const startEdit = (card) => { editCardId.value = card.id; editText.value = card.text; };
    const cancelEdit = () => { editCardId.value = null; editText.value = ""; };
    const saveEdit = async (card) => { if (!editText.value) return; await kanbanHub.invoke("UpdateCard", card.id, editText.value); cancelEdit(); };
    const deleteCard = async (cardId) => await kanbanHub.invoke("DeleteCard", cardId);

    // --- Item Methods ---
    const addItem = async () => {
      if (!newItemName.value) return;
      await itemHub.invoke("AddItem", newItemName.value);
      newItemName.value = "";
    };


    // --- Chat Methods ---

    const sendMessage = async () => {
      if (!newMessage.value) return;
      await chatHub.invoke("SendMessage", userName, newMessage.value, userName);
      newMessage.value = "";
    };
    const sendTyping = () => {
      if (!chatHub) return;
      chatHub.invoke("Typing", userName, true);
      clearTimeout(typingTimeout);
      typingTimeout = setTimeout(() => {
        chatHub.invoke("Typing", userName, false);
      }, 1000);
    };

    const editMsgId = ref(null);
    const editMsgText = ref("");

    const startEditMessage = (msg) => { editMsgId.value = msg.id; editMsgText.value = msg.text; };
    const cancelEditMessage = () => { editMsgId.value = null; editMsgText.value = ""; };
    const saveEditMessage = async (msg) => {
      if (!editMsgText.value) return;
      await chatHub.invoke("UpdateMessage", msg.id, editMsgText.value);
      cancelEditMessage();
    };
    const deleteMessage = async (msgId) => { await chatHub.invoke("DeleteMessage", msgId); };

    // --- Notifications ---
    const sendNotification = async () => {
      await notificationHub.invoke("SendNotification", `Notif at ${new Date().toLocaleTimeString()}`);
    };

    // --- Editor Methods ---
    const sendUpdate = async () => {
      if (!editorHub) return;
      try { await editorHub.invoke("SendUpdate", docName, content.value); } catch (err) { console.error(err); }
    };
    const setupEditor = async () => {
      editorHub = createHub("http://localhost:5284/editorHub");
      editorHub.on("ReceiveUpdate", (newText) => {
        if (document.activeElement !== textareaRef.value) content.value = newText;
      });
      await editorHub.start();
      const initial = await editorHub.invoke("LoadDocument", docName);
      content.value = initial || "";
    };

    // --- Start SignalR ---
    const startConnections = async () => {
      kanbanHub = createHub("http://localhost:5284/kanbanHub", {
        CardAdded: (c) => cards.push(c),
        CardMoved: ({ cardId, columnId }) => { const c = cards.find(x => x.id === cardId); if (c) c.columnId = columnId; },
        CardUpdated: (upd) => { const c = cards.find(x => x.id === upd.id); if (c) c.text = upd.text; },
        CardDeleted: (id) => { const idx = cards.findIndex(x => x.id === id); if (idx !== -1) cards.splice(idx, 1); }
      });
      await kanbanHub.start();
      cards.push(...(await kanbanHub.invoke("GetCards")));

      itemHub = createHub("http://localhost:5284/itemHub", { ItemAdded: (i) => items.push(i) });
      await itemHub.start();
      items.push(...(await itemHub.invoke("GetItems")));

      chatHub = createHub("http://localhost:5284/chatHub", {
        ReceiveMessage: (msg) => messages.push(msg),
        MessageUpdated: (upd) => {
          const m = messages.find(x => x.id === upd.id);
          if (m) m.text = upd.text;
        },
        MessageDeleted: (id) => {
          const idx = messages.findIndex(m => m.id === id);
          if (idx !== -1) messages.splice(idx, 1);
        },
        UserTyping: ({ user, isTyping }) => {
          if (isTyping && !typingUsers.includes(user)) typingUsers.push(user);
          else if (!isTyping) {
            const idx = typingUsers.indexOf(user);
            if (idx !== -1) typingUsers.splice(idx, 1);
          }
        }
      });
      await chatHub.start();
      messages.push(...(await chatHub.invoke("GetMessages")));

      notificationHub = createHub("http://localhost:5284/notificationHub", {
        ReceiveNotification: (n) => notifications.push(n)
      });
      await notificationHub.start();
      notifications.push(...(await notificationHub.invoke("GetNotifications")));
    };

    onMounted(async () => {
      await startConnections();
      await setupEditor();
    });

    return {
      // Kanban
      columns, cards, getCards, draggedCard, newCard, editCardId, editText,
      onDragStart, onDrop, addCard, startEdit, cancelEdit, saveEdit, deleteCard,

      // Items
      items, newItemName, addItem,

      // Chat
      messages, newMessage, sendMessage, typingUsers, sendTyping,
      editMsgId, editMsgText, startEditMessage, cancelEditMessage, saveEditMessage, deleteMessage,
      userName,

      // Notifications
      notifications, sendNotification,

      // Editor
      content, textareaRef, sendUpdate
    };
  }
};
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  max-width: 600px;
  margin: 40px auto;
}

section {
  margin-bottom: 30px;
}

input {
  padding: 5px;
  margin-right: 5px;
}

button {
  padding: 5px 10px;
}

ul {
  list-style: none;
  padding: 0;
}

li {
  padding: 4px 0;
}

.board {
  display: flex;
  gap: 20px;
}

.column {
  background: #f4f4f4;
  padding: 10px;
  width: 180px;
  border-radius: 8px;
}

.card {
  background: white;
  padding: 8px;
  margin: 5px 0;
  cursor: grab;
  border-radius: 4px;
}

.typing-indicator {
  font-style: italic;
  font-size: 12px;
  margin-bottom: 5px;
}

.chat-list li {
  padding: 5px;
  margin-bottom: 3px;
  border-radius: 4px;
  background: #f4f4f4;
}
</style>