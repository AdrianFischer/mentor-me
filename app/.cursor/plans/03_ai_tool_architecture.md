# Plan: AI Tool Architecture (Scalability) (COMPLETED)

## Objective
Refactor the `ToolRegistry` to follow the **Command Pattern** (or Strategy Pattern). This decouples tool definitions from the execution engine, adhering to the Open/Closed Principle.

## Current State
- **File:** `lib/ai_tools/tool_registry.dart`
- **Structure:** A single class with a large `switch` statement for `executeTool` and `describeAction`.
- **Issues:**
  - Hard to maintain as tool count grows.
  - High coupling; adding a tool requires modifying the central registry.

## Proposed Solution
Create an abstract `AiTool` base class and separate implementations for each tool.

## Implementation Steps

### 1. Define Base Class (Completed)
Create `lib/ai_tools/ai_tool.dart`:
```dart
abstract class AiTool {
  String get name;
  String get description;
  Map<String, dynamic> get schema; // specific args definition

  String describeAction(Map<String, dynamic> args);
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService);
}
```

### 2. Implement Concrete Tools (Completed)
Create a directory `lib/ai_tools/implementations/`.
Create files for each tool, e.g., `add_project_tool.dart`:

```dart
class AddProjectTool implements AiTool {
  @override
  String get name => 'add_project';
  
  // ... implement other getters ...

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService service) async {
    final title = args['title'];
    final id = service.addProject(title);
    return {'result': 'success', 'project_id': id};
  }
}
```

### 3. Refactor Registry (Completed)
Update `lib/ai_tools/tool_registry.dart`:
- Maintain a `Map<String, AiTool> _tools`.
- Constructor registers all available tools.
- `executeTool` looks up the tool by name and calls `tool.execute()`.

```dart
class ToolRegistry {
  final Map<String, AiTool> _tools = {};
  final DataService _dataService;

  ToolRegistry(this._dataService) {
    _register(AddProjectTool());
    _register(AddTaskTool());
    // ...
  }
  
  // ... implementation delegating to _tools[name]
}
```

### 4. Dynamic Tool Loading (Optional Future Step)
This structure allows easily adding new tools or enabling/disabling tools dynamically based on context in the future.
