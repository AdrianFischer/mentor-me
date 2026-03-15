import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

/**
 * File-backed conversation storage.
 * Each conversation is stored as data/conversations/{id}.json
 * including its messages.
 */
export class ConversationStore {
  constructor(dataDir) {
    this.dir = path.join(dataDir, 'conversations');
    if (!fs.existsSync(this.dir)) fs.mkdirSync(this.dir, { recursive: true });
  }

  getAllConversations() {
    const convos = [];
    for (const file of fs.readdirSync(this.dir)) {
      if (!file.endsWith('.json')) continue;
      try {
        const data = JSON.parse(fs.readFileSync(path.join(this.dir, file), 'utf-8'));
        convos.push({
          id: data.id,
          title: data.title,
          lastModified: data.lastModified,
          notes: data.notes || null,
        });
      } catch (e) {
        // Skip corrupt files
      }
    }
    return convos.sort((a, b) => new Date(b.lastModified) - new Date(a.lastModified));
  }

  getConversation(id) {
    const filePath = path.join(this.dir, `${id}.json`);
    if (!fs.existsSync(filePath)) return null;
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  }

  createConversation(title) {
    const id = uuidv4();
    const conversation = {
      id,
      title,
      lastModified: new Date().toISOString(),
      notes: null,
      messages: [],
    };
    this._save(conversation);
    return id;
  }

  updateConversation(id, updates) {
    const convo = this.getConversation(id);
    if (!convo) return false;
    if (updates.title !== undefined) convo.title = updates.title;
    if (updates.notes !== undefined) convo.notes = updates.notes;
    convo.lastModified = new Date().toISOString();
    this._save(convo);
    return true;
  }

  deleteConversation(id) {
    const filePath = path.join(this.dir, `${id}.json`);
    if (!fs.existsSync(filePath)) return false;
    fs.unlinkSync(filePath);
    return true;
  }

  getMessages(conversationId) {
    const convo = this.getConversation(conversationId);
    return convo?.messages || [];
  }

  addMessage(conversationId, message) {
    const convo = this.getConversation(conversationId);
    if (!convo) return false;
    convo.messages.push({
      id: uuidv4(),
      text: message.text,
      isUser: message.isUser,
      timestamp: new Date().toISOString(),
      conversationId,
    });
    convo.lastModified = new Date().toISOString();
    this._save(convo);
    return true;
  }

  clearMessages(conversationId) {
    const convo = this.getConversation(conversationId);
    if (!convo) return false;
    convo.messages = [];
    convo.lastModified = new Date().toISOString();
    this._save(convo);
    return true;
  }

  _save(conversation) {
    fs.writeFileSync(
      path.join(this.dir, `${conversation.id}.json`),
      JSON.stringify(conversation, null, 2),
    );
  }
}
