class ToolDefinitions {
  static const List<Map<String, dynamic>> tools = [
    {
      "name": "add_project",
      "description": "Creates a new top-level project container.",
      "parameters": {
        "type": "object",
        "properties": {
          "title": {
            "type": "string",
            "description": "The title of the new project."
          }
        },
        "required": ["title"]
      }
    },
    {
      "name": "add_task",
      "description": "Adds a new task to a specific project. Requires the project_id.",
      "parameters": {
        "type": "object",
        "properties": {
          "project_id": {
            "type": "string",
            "description": "The UUID of the project to add the task to."
          },
          "title": {
            "type": "string",
            "description": "The description of the task."
          }
        },
        "required": ["project_id", "title"]
      }
    },
    {
      "name": "add_subtask",
      "description": "Adds a granular subtask to a specific parent task.",
      "parameters": {
        "type": "object",
        "properties": {
          "task_id": {
            "type": "string",
            "description": "The UUID of the parent task."
          },
          "title": {
            "type": "string",
            "description": "The description of the subtask."
          }
        },
        "required": ["task_id", "title"]
      }
    },
    {
      "name": "set_item_status",
      "description": "Marks a project, task, or subtask as completed or active.",
      "parameters": {
        "type": "object",
        "properties": {
          "item_id": {
            "type": "string",
            "description": "The UUID of the project, task, or subtask."
          },
          "is_completed": {
            "type": "boolean",
            "description": "True for done, false for active."
          }
        },
        "required": ["item_id", "is_completed"]
      }
    },
    {
      "name": "delete_item",
      "description": "Permanently removes a project, task, or subtask by its ID.",
      "parameters": {
        "type": "object",
        "properties": {
          "item_id": {
            "type": "string",
            "description": "The UUID of the item to delete."
          }
        },
        "required": ["item_id"]
      }
    }
  ];
}
