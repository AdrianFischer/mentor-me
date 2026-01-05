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
    },
    {
      "name": "set_task_goal",
      "description": "Sets a numeric or habit goal for a specific task.",
      "parameters": {
        "type": "object",
        "properties": {
          "task_id": { "type": "string", "description": "The UUID of the task." },
          "type": { "type": "string", "enum": ["numeric", "habit"], "description": "The type of goal." },
          "target": { "type": "number", "description": "Target value for numeric (amount) or habit (frequency 0.0-1.0)." },
          "unit": { "type": "string", "description": "Unit for numeric goal (e.g. '\$', 'kg')." }
        },
        "required": ["task_id", "type", "target"]
      }
    },
    {
      "name": "record_goal_progress",
      "description": "Records progress for a task goal.",
      "parameters": {
        "type": "object",
        "properties": {
          "task_id": { "type": "string", "description": "The UUID of the task." },
          "numeric_amount": { "type": "number", "description": "The amount to add/subtract for numeric goals." },
          "habit_success": { "type": "boolean", "description": "True if the habit was performed successfully today." },
          "note": { "type": "string", "description": "Optional note for the entry." }
        },
        "required": ["task_id"]
      }
    },
    {
      "name": "get_project",
      "description": "Retrieves details of a specific project, including its tasks.",
      "parameters": {
        "type": "object",
        "properties": {
          "project_id": {
            "type": "string",
            "description": "The UUID of the project."
          }
        },
        "required": ["project_id"]
      }
    },
    {
      "name": "get_task",
      "description": "Retrieves details of a specific task, including its subtasks.",
      "parameters": {
        "type": "object",
        "properties": {
          "task_id": {
            "type": "string",
            "description": "The UUID of the task."
          }
        },
        "required": ["task_id"]
      }
    },
    {
      "name": "update_item_name",
      "description": "Updates the name (title) of a project, task, or subtask.",
      "parameters": {
        "type": "object",
        "properties": {
          "item_id": {
            "type": "string",
            "description": "The UUID of the project, task, or subtask."
          },
          "new_name": {
            "type": "string",
            "description": "The new name/title for the item."
          }
        },
        "required": ["item_id", "new_name"]
      }
    },
    {
      "name": "update_notes",
      "description": "Updates the notes of a project, task, or subtask.",
      "parameters": {
        "type": "object",
        "properties": {
          "item_id": {
            "type": "string",
            "description": "The UUID of the project, task, or subtask."
          },
          "notes": {
            "type": "string",
            "description": "The new notes content."
          }
        },
        "required": ["item_id", "notes"]
      }
    },
    {
      "name": "set_ai_status",
      "description": "Sets the AI agent status for a task or subtask. Status can be: notReady, ready, inProgress, or done. When status is set to 'done', the item is automatically marked as completed.",
      "parameters": {
        "type": "object",
        "properties": {
          "item_id": {
            "type": "string",
            "description": "The UUID of the task or subtask."
          },
          "status": {
            "type": "string",
            "enum": ["notReady", "ready", "inProgress", "done"],
            "description": "The AI agent status: notReady (paused), ready (ready for agent), inProgress (agent working), or done (completed by agent)."
          }
        },
        "required": ["item_id", "status"]
      }
    },
    {
      'name': 'save_memory',
    'description': 'Save a specific fact, preference, or insight about the user to long-term memory. Use this when the user states something important that should be remembered for future conversations.',
    'parameters': {
      'type': 'object',
      'properties': {
        'fact': {
          'type': 'string',
          'description': 'The clear, concise fact or insight to remember.'
        }
      },
      'required': ['fact']
    }
  }
];
}
