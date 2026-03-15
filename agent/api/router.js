import { Router } from 'express';
import { logger } from '../logger.js';

/**
 * REST API router for the backend data service.
 * Mounts under /api/v1/ on the existing Express app.
 */
export function createApiRouter(dataService, conversationStore, knowledgeStore, memoryStore) {
  const router = Router();

  // Request logging
  router.use((req, res, next) => {
    if (req.path !== '/events') {
      logger.info(`API ${req.method} ${req.path}`);
    }
    next();
  });

  // ─── SSE Clients ───
  const sseClients = new Set();

  dataService.on('change', () => {
    for (const res of sseClients) {
      try {
        res.write(`data: ${JSON.stringify({ type: 'data_changed', timestamp: new Date().toISOString() })}\n\n`);
      } catch (e) {
        sseClients.delete(res);
      }
    }
  });

  // ─── Health ───

  router.get('/health', (req, res) => {
    res.json({ status: 'ok', uptime: process.uptime(), timestamp: new Date().toISOString() });
  });

  // ─── SSE Events ───

  router.get('/events', (req, res) => {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    });
    res.write(`data: ${JSON.stringify({ type: 'connected' })}\n\n`);
    sseClients.add(res);
    req.on('close', () => sseClients.delete(res));
  });

  // ─── Projects ───

  router.get('/projects', (req, res) => {
    res.json(dataService.getAllProjects().map(sanitizeProject));
  });

  router.get('/projects/:id', (req, res) => {
    const project = dataService.getProject(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });
    res.json(sanitizeProject(project));
  });

  router.post('/projects', (req, res) => {
    const { title } = req.body;
    if (!title) return res.status(400).json({ error: 'title is required' });
    const id = dataService.addProject(title);
    res.status(201).json({ id });
  });

  router.put('/projects/:id', (req, res) => {
    // Full project replacement (used by Flutter's saveProject)
    const projectData = req.body;
    if (!projectData.id) projectData.id = req.params.id;
    dataService.upsertProject(projectData);
    res.json(sanitizeProject(dataService.getProject(req.params.id)));
  });

  router.patch('/projects/:id', (req, res) => {
    const { title, is_completed, isCompleted, notes } = req.body;
    const project = dataService.getProject(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });
    if (title !== undefined) dataService.updateTitle(req.params.id, title);
    if (notes !== undefined) dataService.updateNotes(req.params.id, notes);
    const completed = is_completed ?? isCompleted;
    if (completed !== undefined) dataService.setItemStatus(req.params.id, completed);
    res.json(sanitizeProject(dataService.getProject(req.params.id)));
  });

  router.delete('/projects/:id', (req, res) => {
    if (!dataService.deleteItem(req.params.id)) return res.status(404).json({ error: 'Project not found' });
    res.json({ success: true });
  });

  // ─── Tasks ───

  router.get('/tasks/:id', (req, res) => {
    const task = dataService.getTask(req.params.id);
    if (!task) return res.status(404).json({ error: 'Task not found' });
    res.json(task);
  });

  router.post('/projects/:pid/tasks', (req, res) => {
    const { title } = req.body;
    if (!title) return res.status(400).json({ error: 'title is required' });
    const id = dataService.addTask(req.params.pid, title);
    if (!id) return res.status(404).json({ error: 'Project not found' });
    res.status(201).json({ id });
  });

  router.patch('/tasks/:id', (req, res) => {
    const { title, is_completed, notes, ai_status } = req.body;
    const found = dataService.findItem(req.params.id);
    if (!found) return res.status(404).json({ error: 'Task not found' });
    if (title !== undefined) dataService.updateTitle(req.params.id, title);
    if (notes !== undefined) dataService.updateNotes(req.params.id, notes);
    if (is_completed !== undefined) dataService.setItemStatus(req.params.id, is_completed);
    if (ai_status !== undefined) dataService.setAiStatus(req.params.id, ai_status);
    res.json(dataService.getTask(req.params.id));
  });

  router.delete('/tasks/:id', (req, res) => {
    if (!dataService.deleteItem(req.params.id)) return res.status(404).json({ error: 'Task not found' });
    res.json({ success: true });
  });

  // ─── Task Goals ───

  router.post('/tasks/:id/goal', (req, res) => {
    const { type, target, unit } = req.body;
    if (!type) return res.status(400).json({ error: 'type is required' });
    const goalDef = { type, target, unit, current: 0 };
    if (!dataService.setTaskGoal(req.params.id, goalDef)) {
      return res.status(404).json({ error: 'Task not found' });
    }
    res.json({ success: true });
  });

  router.post('/tasks/:id/goal/progress', (req, res) => {
    const { amount, is_success, note } = req.body;
    const progress = {};
    if (amount !== undefined) progress.amount = amount;
    if (is_success !== undefined) progress.isSuccess = is_success;
    if (note !== undefined) progress.note = note;
    if (!dataService.recordGoalProgress(req.params.id, progress)) {
      return res.status(404).json({ error: 'Task or goal not found' });
    }
    res.json({ success: true });
  });

  // ─── Subtasks ───

  router.post('/tasks/:tid/subtasks', (req, res) => {
    const { title } = req.body;
    if (!title) return res.status(400).json({ error: 'title is required' });
    const id = dataService.addSubtask(req.params.tid, title);
    if (!id) return res.status(404).json({ error: 'Task not found' });
    res.status(201).json({ id });
  });

  router.patch('/subtasks/:id', (req, res) => {
    const { title, is_completed, notes, ai_status } = req.body;
    const found = dataService.findItem(req.params.id);
    if (!found) return res.status(404).json({ error: 'Subtask not found' });
    if (title !== undefined) dataService.updateTitle(req.params.id, title);
    if (notes !== undefined) dataService.updateNotes(req.params.id, notes);
    if (is_completed !== undefined) dataService.setItemStatus(req.params.id, is_completed);
    if (ai_status !== undefined) dataService.setAiStatus(req.params.id, ai_status);
    res.json({ success: true });
  });

  router.delete('/subtasks/:id', (req, res) => {
    if (!dataService.deleteItem(req.params.id)) return res.status(404).json({ error: 'Subtask not found' });
    res.json({ success: true });
  });

  // ─── Listing & Session ───

  router.get('/todos', (req, res) => {
    const status = req.query.status || 'active';
    res.json(dataService.listTodosByStatus(status));
  });

  router.patch('/todos/by-index/:idx', (req, res) => {
    const idx = parseInt(req.params.idx, 10);
    if (isNaN(idx)) return res.status(400).json({ error: 'Invalid index' });
    if (!dataService.updateByIndex(idx, req.body)) {
      return res.status(404).json({ error: 'No item at that index (call GET /todos first)' });
    }
    res.json({ success: true });
  });

  // ─── Memories ───

  router.get('/memories', (req, res) => {
    res.json(memoryStore.getAll());
  });

  router.post('/memories', (req, res) => {
    const { fact } = req.body;
    if (!fact) return res.status(400).json({ error: 'fact is required' });
    const id = memoryStore.save(fact);
    res.status(201).json({ id });
  });

  router.delete('/memories/:id', (req, res) => {
    if (!memoryStore.delete(req.params.id)) return res.status(404).json({ error: 'Memory not found' });
    res.json({ success: true });
  });

  // ─── Knowledge ───

  router.get('/knowledge', (req, res) => {
    res.json(knowledgeStore.getAll());
  });

  router.post('/knowledge', (req, res) => {
    const { content } = req.body;
    if (!content) return res.status(400).json({ error: 'content is required' });
    const id = knowledgeStore.create(content);
    res.status(201).json({ id });
  });

  router.delete('/knowledge/:id', (req, res) => {
    if (!knowledgeStore.delete(req.params.id)) return res.status(404).json({ error: 'Knowledge entry not found' });
    res.json({ success: true });
  });

  // ─── Conversations ───

  router.get('/conversations', (req, res) => {
    res.json(conversationStore.getAllConversations());
  });

  router.post('/conversations', (req, res) => {
    const { title } = req.body;
    if (!title) return res.status(400).json({ error: 'title is required' });
    const id = conversationStore.createConversation(title);
    res.status(201).json({ id });
  });

  router.patch('/conversations/:id', (req, res) => {
    if (!conversationStore.updateConversation(req.params.id, req.body)) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    res.json({ success: true });
  });

  router.delete('/conversations/:id', (req, res) => {
    if (!conversationStore.deleteConversation(req.params.id)) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    res.json({ success: true });
  });

  router.get('/conversations/:id/messages', (req, res) => {
    const messages = conversationStore.getMessages(req.params.id);
    res.json(messages);
  });

  router.post('/conversations/:id/messages', (req, res) => {
    const { text, isUser } = req.body;
    if (!text) return res.status(400).json({ error: 'text is required' });
    if (!conversationStore.addMessage(req.params.id, { text, isUser: isUser ?? true })) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    res.json({ success: true });
  });

  return router;
}

/** Strip internal _filePath from project before sending to clients */
function sanitizeProject(project) {
  const { _filePath, ...rest } = project;
  return rest;
}
