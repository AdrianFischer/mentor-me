import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

/**
 * File-backed knowledge storage.
 * Each entry stored as data/knowledge/{id}.json
 */
export class KnowledgeStore {
  constructor(dataDir) {
    this.dir = path.join(dataDir, 'knowledge');
    if (!fs.existsSync(this.dir)) fs.mkdirSync(this.dir, { recursive: true });
  }

  getAll() {
    const entries = [];
    for (const file of fs.readdirSync(this.dir)) {
      if (!file.endsWith('.json')) continue;
      try {
        entries.push(JSON.parse(fs.readFileSync(path.join(this.dir, file), 'utf-8')));
      } catch (e) {
        // Skip corrupt files
      }
    }
    return entries.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  get(id) {
    const filePath = path.join(this.dir, `${id}.json`);
    if (!fs.existsSync(filePath)) return null;
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  }

  create(content) {
    const id = uuidv4();
    const entry = {
      id,
      content,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    fs.writeFileSync(path.join(this.dir, `${id}.json`), JSON.stringify(entry, null, 2));
    return id;
  }

  update(id, content) {
    const entry = this.get(id);
    if (!entry) return false;
    entry.content = content;
    entry.updatedAt = new Date().toISOString();
    fs.writeFileSync(path.join(this.dir, `${id}.json`), JSON.stringify(entry, null, 2));
    return true;
  }

  delete(id) {
    const filePath = path.join(this.dir, `${id}.json`);
    if (!fs.existsSync(filePath)) return false;
    fs.unlinkSync(filePath);
    return true;
  }
}
