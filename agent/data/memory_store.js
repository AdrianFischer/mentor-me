import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

/**
 * File-backed memory storage.
 * All memories stored in a single data/memories.json file (small atomic facts).
 */
export class MemoryStore {
  constructor(dataDir) {
    this.filePath = path.join(dataDir, 'memories.json');
  }

  getAll() {
    if (!fs.existsSync(this.filePath)) return [];
    try {
      return JSON.parse(fs.readFileSync(this.filePath, 'utf-8'));
    } catch (e) {
      return [];
    }
  }

  save(fact) {
    const memories = this.getAll();
    const memory = {
      id: uuidv4(),
      fact,
      timestamp: new Date().toISOString(),
    };
    memories.push(memory);
    this._write(memories);
    return memory.id;
  }

  delete(id) {
    const memories = this.getAll();
    const idx = memories.findIndex(m => m.id === id);
    if (idx === -1) return false;
    memories.splice(idx, 1);
    this._write(memories);
    return true;
  }

  _write(memories) {
    const dir = path.dirname(this.filePath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(this.filePath, JSON.stringify(memories, null, 2));
  }
}
