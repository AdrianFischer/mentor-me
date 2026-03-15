import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { EventEmitter } from 'events';
import { parseProject, toMarkdown } from './markdown_parser.js';

/**
 * Backend data service that owns project/task data.
 * Reads/writes Markdown files in data/todos/ and keeps an in-memory cache.
 * Direct port of the Flutter ProjectService + FileSystemService behavior.
 */
export class DataService extends EventEmitter {
  constructor(dataDir) {
    super();
    this.dataDir = dataDir;
    this.todosDir = path.join(dataDir, 'todos');
    this.projects = [];
    this._recentWrites = new Map(); // path -> timestamp (loop prevention)
    this._watcher = null;
    this._saveDebounce = new Map(); // projectId -> timeout
    this._sessionIndex = new Map(); // 1-based index -> id
    this._sessionCounter = 0;
  }

  async init() {
    await this.loadAllProjects();
    this._startWatcher();
  }

  // ─── Loading ───

  async loadAllProjects() {
    const files = this._walkDir(this.todosDir);
    this.projects = [];
    for (const filePath of files) {
      try {
        const content = fs.readFileSync(filePath, 'utf-8');
        const project = parseProject(content);
        project._filePath = filePath; // Track source file for saves
        this.projects.push(project);
      } catch (e) {
        console.error(`Error parsing ${filePath}:`, e.message);
      }
    }
    return this.projects;
  }

  _walkDir(dir) {
    if (!fs.existsSync(dir)) return [];
    const files = [];
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        files.push(...this._walkDir(fullPath));
      } else if (entry.name.endsWith('.md') && entry.name !== 'README.md') {
        files.push(fullPath);
      }
    }
    return files;
  }

  // ─── File Watching ───

  _startWatcher() {
    if (!fs.existsSync(this.todosDir)) return;
    this._watcher = fs.watch(this.todosDir, { recursive: true }, (eventType, filename) => {
      if (!filename || !filename.endsWith('.md')) return;
      const fullPath = path.join(this.todosDir, filename);
      // Loop prevention: ignore our own writes within 2 seconds
      const lastWrite = this._recentWrites.get(fullPath);
      if (lastWrite && Date.now() - lastWrite < 2000) return;
      // Reload
      setTimeout(() => {
        this.loadAllProjects().then(() => this.emit('change'));
      }, 200);
    });
  }

  stopWatcher() {
    if (this._watcher) {
      this._watcher.close();
      this._watcher = null;
    }
  }

  // ─── Persistence ───

  _saveProject(project) {
    const markdown = toMarkdown(project);
    const filePath = project._filePath || this._defaultFilePath(project);
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    this._recentWrites.set(filePath, Date.now());
    fs.writeFileSync(filePath, markdown, 'utf-8');
    project._filePath = filePath;
  }

  _debouncedSave(project) {
    const existing = this._saveDebounce.get(project.id);
    if (existing) clearTimeout(existing);
    this._saveDebounce.set(project.id, setTimeout(() => {
      this._saveProject(project);
      this._saveDebounce.delete(project.id);
    }, 500));
  }

  _defaultFilePath(project) {
    const safeName = project.title.toLowerCase()
      .replace(/[^a-z0-9äöüß]+/g, '_')
      .replace(/^_|_$/g, '')
      .substring(0, 60);
    return path.join(this.todosDir, 'unsorted', `${safeName}.md`);
  }

  // ─── Project CRUD ───

  getAllProjects() {
    return this.projects;
  }

  getProject(id) {
    return this.projects.find(p => p.id === id) || null;
  }

  addProject(title) {
    const id = uuidv4();
    const project = {
      id,
      title,
      isCompleted: false,
      tags: [],
      notes: null,
      tasks: [],
    };
    this.projects.push(project);
    this._saveProject(project);
    this.emit('change');
    return id;
  }

  upsertProject(projectData) {
    const idx = this.projects.findIndex(p => p.id === projectData.id);
    if (idx !== -1) {
      // Preserve internal _filePath
      projectData._filePath = this.projects[idx]._filePath;
      this.projects[idx] = projectData;
    } else {
      this.projects.push(projectData);
    }
    this._saveProject(projectData);
    this.emit('change');
  }

  deleteProject(id) {
    const idx = this.projects.findIndex(p => p.id === id);
    if (idx === -1) return false;
    const project = this.projects[idx];
    if (project._filePath && fs.existsSync(project._filePath)) {
      this._recentWrites.set(project._filePath, Date.now());
      fs.unlinkSync(project._filePath);
    }
    this.projects.splice(idx, 1);
    this.emit('change');
    return true;
  }

  // ─── Task CRUD ───

  addTask(projectId, title) {
    const project = this.getProject(projectId);
    if (!project) return null;
    const id = uuidv4();
    const task = {
      id,
      title,
      isCompleted: false,
      projectId,
      notes: null,
      subtasks: [],
    };
    project.tasks.push(task);
    this._debouncedSave(project);
    this.emit('change');
    return id;
  }

  getTask(taskId) {
    for (const project of this.projects) {
      const task = project.tasks.find(t => t.id === taskId);
      if (task) return { ...task, projectId: project.id };
    }
    return null;
  }

  // ─── Subtask CRUD ───

  addSubtask(taskId, title) {
    const { project, task } = this._findTask(taskId);
    if (!project || !task) return null;
    const id = uuidv4();
    const subtask = { id, title, isCompleted: false, notes: null };
    task.subtasks.push(subtask);
    this._debouncedSave(project);
    this.emit('change');
    return id;
  }

  // ─── Item Operations (work on project, task, or subtask by ID) ───

  findItem(id) {
    for (const project of this.projects) {
      if (project.id === id) return { type: 'project', item: project, project };
      for (const task of project.tasks) {
        if (task.id === id) return { type: 'task', item: task, project };
        for (const subtask of task.subtasks) {
          if (subtask.id === id) return { type: 'subtask', item: subtask, project, task };
        }
      }
    }
    return null;
  }

  setItemStatus(id, isCompleted) {
    const found = this.findItem(id);
    if (!found) return false;
    found.item.isCompleted = isCompleted;
    // If it's a task marked done, also mark its subtasks
    if (found.type === 'task' && isCompleted) {
      for (const sub of found.item.subtasks) sub.isCompleted = true;
    }
    this._debouncedSave(found.project);
    this.emit('change');
    return true;
  }

  setAiStatus(id, status) {
    const found = this.findItem(id);
    if (!found) return false;
    found.item.aiStatus = status;
    if (status === 'done') {
      found.item.isCompleted = true;
    }
    this._debouncedSave(found.project);
    this.emit('change');
    return true;
  }

  updateTitle(id, newTitle) {
    const found = this.findItem(id);
    if (!found) return false;
    found.item.title = newTitle;
    this._debouncedSave(found.project);
    this.emit('change');
    return true;
  }

  updateNotes(id, notes) {
    const found = this.findItem(id);
    if (!found) return false;
    found.item.notes = notes;
    this._debouncedSave(found.project);
    this.emit('change');
    return true;
  }

  deleteItem(id) {
    for (const project of this.projects) {
      if (project.id === id) return this.deleteProject(id);
      for (let ti = 0; ti < project.tasks.length; ti++) {
        if (project.tasks[ti].id === id) {
          project.tasks.splice(ti, 1);
          this._debouncedSave(project);
          this.emit('change');
          return true;
        }
        const task = project.tasks[ti];
        for (let si = 0; si < task.subtasks.length; si++) {
          if (task.subtasks[si].id === id) {
            task.subtasks.splice(si, 1);
            this._debouncedSave(project);
            this.emit('change');
            return true;
          }
        }
      }
    }
    return false;
  }

  // ─── Goals ───

  setTaskGoal(taskId, goalDef) {
    const { project, task } = this._findTask(taskId);
    if (!project || !task) return false;
    task.goal = { ...goalDef, history: [] };
    // Store goals as sidecar JSON since Markdown doesn't support them
    this._saveGoal(taskId, task.goal);
    this.emit('change');
    return true;
  }

  recordGoalProgress(taskId, progress) {
    const { project, task } = this._findTask(taskId);
    if (!project || !task || !task.goal) return false;
    if (!task.goal.history) task.goal.history = [];
    task.goal.history.push({ ...progress, id: uuidv4(), date: new Date().toISOString() });
    if (task.goal.type === 'numeric' && progress.amount != null) {
      task.goal.current = (task.goal.current || 0) + progress.amount;
    }
    this._saveGoal(taskId, task.goal);
    this.emit('change');
    return true;
  }

  _saveGoal(taskId, goal) {
    const goalsDir = path.join(this.todosDir, '.goals');
    if (!fs.existsSync(goalsDir)) fs.mkdirSync(goalsDir, { recursive: true });
    fs.writeFileSync(path.join(goalsDir, `${taskId}.json`), JSON.stringify(goal, null, 2));
  }

  _loadGoals() {
    const goalsDir = path.join(this.todosDir, '.goals');
    if (!fs.existsSync(goalsDir)) return;
    for (const file of fs.readdirSync(goalsDir)) {
      if (!file.endsWith('.json')) continue;
      const taskId = file.replace('.json', '');
      try {
        const goal = JSON.parse(fs.readFileSync(path.join(goalsDir, file), 'utf-8'));
        const { task } = this._findTask(taskId);
        if (task) task.goal = goal;
      } catch (e) {
        // Ignore corrupt goal files
      }
    }
  }

  // ─── Session Index (1-based, for voice/CLI) ───

  clearSessionIndex() {
    this._sessionIndex.clear();
    this._sessionCounter = 0;
  }

  addToSessionIndex(id) {
    this._sessionCounter++;
    this._sessionIndex.set(this._sessionCounter, id);
    return this._sessionCounter;
  }

  getIdFromSessionIndex(index) {
    return this._sessionIndex.get(index) || null;
  }

  // ─── Listing ───

  listTodosByStatus(status = 'active') {
    this.clearSessionIndex();
    const results = [];
    for (const project of this.projects) {
      if (status === 'completed' && !project.isCompleted) continue;
      if (status === 'active' && project.isCompleted) continue;
      for (const task of project.tasks) {
        if (status === 'completed' && !task.isCompleted) continue;
        if (status === 'active' && task.isCompleted) continue;
        const idx = this.addToSessionIndex(task.id);
        results.push({
          index: idx,
          id: task.id,
          title: task.title,
          isCompleted: task.isCompleted,
          projectId: project.id,
          projectTitle: project.title,
          subtasks: task.subtasks.map(s => ({
            id: s.id,
            title: s.title,
            isCompleted: s.isCompleted,
          })),
        });
      }
    }
    return results;
  }

  updateByIndex(index, updates) {
    const id = this.getIdFromSessionIndex(index);
    if (!id) return false;
    if (updates.new_title) this.updateTitle(id, updates.new_title);
    if (updates.notes !== undefined) this.updateNotes(id, updates.notes);
    if (updates.is_completed !== undefined) this.setItemStatus(id, updates.is_completed);
    return true;
  }

  // ─── Helpers ───

  _findTask(taskId) {
    for (const project of this.projects) {
      const task = project.tasks.find(t => t.id === taskId);
      if (task) return { project, task };
    }
    return { project: null, task: null };
  }
}
