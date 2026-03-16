import { describe, it, expect, vi, beforeEach } from 'vitest';
import { TaskTools } from '../task_tools.js';

describe('TaskTools', () => {
  let mockDataService;
  let taskTools;

  beforeEach(() => {
    mockDataService = {
      getAllProjects: vi.fn(),
      getTask: vi.fn(),
      listTodosByStatus: vi.fn(),
      addProject: vi.fn(),
      addTask: vi.fn(),
      addSubtask: vi.fn(),
      updateByIndex: vi.fn(),
      updateTitle: vi.fn(),
      setItemStatus: vi.fn(),
      deleteItem: vi.fn(),
    };
    taskTools = new TaskTools(mockDataService);
  });

  it('provides a list of tools', () => {
    const tools = taskTools.getTools();
    expect(tools.length).toBe(10);
    const names = tools.map(t => t.name);
    expect(names).toContain('get_projects');
    expect(names).toContain('get_task');
    expect(names).toContain('list_todos_by_status');
    expect(names).toContain('add_project');
    expect(names).toContain('add_task');
    expect(names).toContain('add_subtask');
    expect(names).toContain('update_todo_by_index');
    expect(names).toContain('update_item_name');
    expect(names).toContain('set_item_status');
    expect(names).toContain('delete_item');
  });

  it('executes get_projects successfully', async () => {
    mockDataService.getAllProjects.mockReturnValue([
      { id: '1', title: 'P1', isCompleted: false, tags: [], tasks: [{}, {}] }
    ]);

    const result = await taskTools.executeTool({ name: 'get_projects' });
    expect(result.result).toBe('success');
    expect(result.projects.length).toBe(1);
    expect(result.projects[0].taskCount).toBe(2);
  });

  it('handles get_projects errors', async () => {
    mockDataService.getAllProjects.mockImplementation(() => { throw new Error('DB error'); });
    const result = await taskTools.executeTool({ name: 'get_projects' });
    expect(result.result).toBe('error');
    expect(result.message).toBe('DB error');
  });

  it('executes get_task successfully', async () => {
    mockDataService.getTask.mockReturnValue({ id: 'task-1', title: 'Task 1' });
    
    const result = await taskTools.executeTool({ name: 'get_task', args: { task_id: 'task-1' } });
    expect(result.result).toBe('success');
    expect(result.task.title).toBe('Task 1');
  });

  it('handles get_task missing args', async () => {
    const result = await taskTools.executeTool({ name: 'get_task', args: {} });
    expect(result.result).toBe('error');
    expect(result.message).toMatch(/Missing task_id/);
  });

  it('handles get_task not found', async () => {
    mockDataService.getTask.mockReturnValue(null);
    const result = await taskTools.executeTool({ name: 'get_task', args: { task_id: 'unknown' } });
    expect(result.result).toBe('error');
    expect(result.message).toMatch(/Task not found/);
  });

  it('executes list_todos_by_status successfully', async () => {
    mockDataService.listTodosByStatus.mockReturnValue([
      { index: 1, title: 'Task 1' }
    ]);

    const result = await taskTools.executeTool({ name: 'list_todos_by_status', args: { status: 'active' } });
    expect(result.result).toBe('success');
    expect(mockDataService.listTodosByStatus).toHaveBeenCalledWith('active');
    expect(result.items.length).toBe(1);
  });

  it('executes list_todos_by_status with default status', async () => {
    mockDataService.listTodosByStatus.mockReturnValue([]);
    
    const result = await taskTools.executeTool({ name: 'list_todos_by_status', args: {} });
    expect(result.result).toBe('success');
    expect(mockDataService.listTodosByStatus).toHaveBeenCalledWith('active');
  });

  // Write Tools Tests
  it('executes add_project successfully', async () => {
    mockDataService.addProject.mockReturnValue('new-proj-id');
    const result = await taskTools.executeTool({ name: 'add_project', args: { title: 'New Proj' } });
    expect(result.result).toBe('success');
    expect(result.project_id).toBe('new-proj-id');
  });

  it('executes add_task successfully', async () => {
    mockDataService.addTask.mockReturnValue('new-task-id');
    const result = await taskTools.executeTool({ name: 'add_task', args: { project_id: 'p1', title: 'New Task' } });
    expect(result.result).toBe('success');
    expect(result.task_id).toBe('new-task-id');
  });

  it('executes add_subtask successfully', async () => {
    mockDataService.addSubtask.mockReturnValue('new-sub-id');
    const result = await taskTools.executeTool({ name: 'add_subtask', args: { task_id: 't1', title: 'New Sub' } });
    expect(result.result).toBe('success');
    expect(result.subtask_id).toBe('new-sub-id');
  });

  it('executes update_todo_by_index successfully', async () => {
    mockDataService.updateByIndex.mockReturnValue(true);
    const result = await taskTools.executeTool({ name: 'update_todo_by_index', args: { index: 1, new_title: 'Updated' } });
    expect(result.result).toBe('success');
    expect(mockDataService.updateByIndex).toHaveBeenCalledWith(1, { index: 1, new_title: 'Updated' });
  });

  it('executes update_item_name successfully', async () => {
    mockDataService.updateTitle.mockReturnValue(true);
    const result = await taskTools.executeTool({ name: 'update_item_name', args: { id: 'item1', new_title: 'Updated Name' } });
    expect(result.result).toBe('success');
    expect(mockDataService.updateTitle).toHaveBeenCalledWith('item1', 'Updated Name');
  });

  it('executes set_item_status successfully', async () => {
    mockDataService.setItemStatus.mockReturnValue(true);
    const result = await taskTools.executeTool({ name: 'set_item_status', args: { id: 'item1', is_completed: true } });
    expect(result.result).toBe('success');
    expect(mockDataService.setItemStatus).toHaveBeenCalledWith('item1', true);
  });

  it('executes delete_item successfully', async () => {
    mockDataService.deleteItem.mockReturnValue(true);
    const result = await taskTools.executeTool({ name: 'delete_item', args: { id: 'item1' } });
    expect(result.result).toBe('success');
    expect(mockDataService.deleteItem).toHaveBeenCalledWith('item1');
  });

  it('handles write tools when item not found', async () => {
    mockDataService.deleteItem.mockReturnValue(false);
    const result = await taskTools.executeTool({ name: 'delete_item', args: { id: 'unknown' } });
    expect(result.result).toBe('error');
    expect(result.message).toMatch(/not found/);
  });

  it('throws for unknown tools', async () => {
    await expect(taskTools.executeTool({ name: 'unknown_tool' })).rejects.toThrow(/Unknown tool: unknown_tool/);
  });
});
