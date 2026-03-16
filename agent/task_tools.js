import { logger } from './logger.js';

export class TaskTools {
  constructor(dataService) {
    this.dataService = dataService;
  }

  getTools() {
    return [
      {
        name: 'get_projects',
        description: 'Lists all projects and their basic metadata (without full task lists).',
        inputSchema: { type: 'object', properties: {} }
      },
      {
        name: 'get_task',
        description: 'Gets a single task and all its subtasks by ID.',
        inputSchema: {
          type: 'object',
          properties: {
            task_id: { type: 'string', description: 'The UUID of the task to retrieve.' }
          },
          required: ['task_id']
        }
      },
      {
        name: 'list_todos_by_status',
        description: 'Lists all todos (projects and tasks) filtered by status. Assigns a session index (1, 2, 3...) to each task for easy reference.',
        inputSchema: {
          type: 'object',
          properties: {
            status: { type: 'string', enum: ['active', 'completed', 'all'], description: 'Status to filter by (default is active).' }
          }
        }
      },
      {
        name: 'add_project',
        description: 'Creates a new project list.',
        inputSchema: {
          type: 'object',
          properties: {
            title: { type: 'string', description: 'The title of the new project.' }
          },
          required: ['title']
        }
      },
      {
        name: 'add_task',
        description: 'Adds a new task to an existing project.',
        inputSchema: {
          type: 'object',
          properties: {
            project_id: { type: 'string', description: 'The UUID of the project.' },
            title: { type: 'string', description: 'The title of the new task.' }
          },
          required: ['project_id', 'title']
        }
      },
      {
        name: 'add_subtask',
        description: 'Adds a new subtask to an existing task.',
        inputSchema: {
          type: 'object',
          properties: {
            task_id: { type: 'string', description: 'The UUID of the parent task.' },
            title: { type: 'string', description: 'The title of the new subtask.' }
          },
          required: ['task_id', 'title']
        }
      },
      {
        name: 'update_todo_by_index',
        description: 'Updates a todo item (task/subtask) using its session index.',
        inputSchema: {
          type: 'object',
          properties: {
            index: { type: 'number', description: 'The session index of the item (e.g., 1, 2, 3).' },
            new_title: { type: 'string', description: 'The new title for the item.' },
            notes: { type: 'string', description: 'The new notes for the item.' },
            is_completed: { type: 'boolean', description: 'The new completion status for the item.' }
          },
          required: ['index']
        }
      },
      {
        name: 'update_item_name',
        description: 'Updates the title of a project, task, or subtask by its UUID.',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'The UUID of the item.' },
            new_title: { type: 'string', description: 'The new title.' }
          },
          required: ['id', 'new_title']
        }
      },
      {
        name: 'set_item_status',
        description: 'Sets the completion status of a project, task, or subtask by its UUID.',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'The UUID of the item.' },
            is_completed: { type: 'boolean', description: 'The boolean status.' }
          },
          required: ['id', 'is_completed']
        }
      },
      {
        name: 'delete_item',
        description: 'Deletes a project, task, or subtask by its UUID.',
        inputSchema: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'The UUID of the item to delete.' }
          },
          required: ['id']
        }
      }
    ];
  }

  async executeTool(call) {
    if (call.name === 'get_projects') {
      return this._getProjects();
    } else if (call.name === 'get_task') {
      return this._getTask(call.args);
    } else if (call.name === 'list_todos_by_status') {
      return this._listTodosByStatus(call.args);
    } else if (call.name === 'add_project') {
      return this._addProject(call.args);
    } else if (call.name === 'add_task') {
      return this._addTask(call.args);
    } else if (call.name === 'add_subtask') {
      return this._addSubtask(call.args);
    } else if (call.name === 'update_todo_by_index') {
      return this._updateTodoByIndex(call.args);
    } else if (call.name === 'update_item_name') {
      return this._updateItemName(call.args);
    } else if (call.name === 'set_item_status') {
      return this._setItemStatus(call.args);
    } else if (call.name === 'delete_item') {
      return this._deleteItem(call.args);
    }
    throw new Error(`Unknown tool: ${call.name}`);
  }

  _getProjects() {
    try {
      const projects = this.dataService.getAllProjects().map(p => ({
        id: p.id,
        title: p.title,
        isCompleted: p.isCompleted,
        tags: p.tags,
        taskCount: p.tasks.length
      }));
      return { result: 'success', projects };
    } catch (e) {
      logger.error('Error in get_projects tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _getTask(args) {
    try {
      if (!args || !args.task_id) {
        return { result: 'error', message: 'Missing task_id argument' };
      }
      const task = this.dataService.getTask(args.task_id);
      if (!task) {
        return { result: 'error', message: `Task not found with ID: ${args.task_id}` };
      }
      return { result: 'success', task };
    } catch (e) {
      logger.error('Error in get_task tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _listTodosByStatus(args) {
    try {
      const status = (args && args.status) ? args.status : 'active';
      const items = this.dataService.listTodosByStatus(status);
      return { result: 'success', items };
    } catch (e) {
      logger.error('Error in list_todos_by_status tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _addProject(args) {
    try {
      if (!args || !args.title) return { result: 'error', message: 'Missing title argument' };
      const id = this.dataService.addProject(args.title);
      return { result: 'success', message: 'Project created successfully', project_id: id };
    } catch (e) {
      logger.error('Error in add_project tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _addTask(args) {
    try {
      if (!args || !args.project_id || !args.title) return { result: 'error', message: 'Missing required arguments: project_id and title' };
      const id = this.dataService.addTask(args.project_id, args.title);
      if (!id) return { result: 'error', message: 'Failed to add task, ensure project_id is valid.' };
      return { result: 'success', message: 'Task added successfully', task_id: id };
    } catch (e) {
      logger.error('Error in add_task tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _addSubtask(args) {
    try {
      if (!args || !args.task_id || !args.title) return { result: 'error', message: 'Missing required arguments: task_id and title' };
      const id = this.dataService.addSubtask(args.task_id, args.title);
      if (!id) return { result: 'error', message: 'Failed to add subtask, ensure task_id is valid.' };
      return { result: 'success', message: 'Subtask added successfully', subtask_id: id };
    } catch (e) {
      logger.error('Error in add_subtask tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _updateTodoByIndex(args) {
    try {
      if (!args || args.index === undefined) return { result: 'error', message: 'Missing index argument' };
      const success = this.dataService.updateByIndex(args.index, args);
      if (!success) return { result: 'error', message: `Item with index ${args.index} not found.` };
      return { result: 'success', message: 'Item updated successfully' };
    } catch (e) {
      logger.error('Error in update_todo_by_index tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _updateItemName(args) {
    try {
      if (!args || !args.id || !args.new_title) return { result: 'error', message: 'Missing required arguments: id and new_title' };
      const success = this.dataService.updateTitle(args.id, args.new_title);
      if (!success) return { result: 'error', message: `Item with id ${args.id} not found.` };
      return { result: 'success', message: 'Item title updated successfully' };
    } catch (e) {
      logger.error('Error in update_item_name tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _setItemStatus(args) {
    try {
      if (!args || !args.id || args.is_completed === undefined) return { result: 'error', message: 'Missing required arguments: id and is_completed' };
      const success = this.dataService.setItemStatus(args.id, args.is_completed);
      if (!success) return { result: 'error', message: `Item with id ${args.id} not found.` };
      return { result: 'success', message: 'Item status updated successfully' };
    } catch (e) {
      logger.error('Error in set_item_status tool:', e);
      return { result: 'error', message: e.message };
    }
  }

  _deleteItem(args) {
    try {
      if (!args || !args.id) return { result: 'error', message: 'Missing id argument' };
      const success = this.dataService.deleteItem(args.id);
      if (!success) return { result: 'error', message: `Item with id ${args.id} not found.` };
      return { result: 'success', message: 'Item deleted successfully' };
    } catch (e) {
      logger.error('Error in delete_item tool:', e);
      return { result: 'error', message: e.message };
    }
  }
}
