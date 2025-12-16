import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/models/ai_models.dart';

void main() {
  group('AI Assistant Logic Tests', () {
    late DataService dataService;
    late ToolRegistry registry;

    setUp(() {
      dataService = DataService();
      // Initialize with some dummy data if needed, though DataService constructor is empty
      // dataService.initData(); // DataService.initData() exists but adds default data
      registry = ToolRegistry(dataService);
    });

    test('ToolRegistry describes add_project correctly', () {
      final description = registry.describeAction('add_project', {'title': 'New Project'});
      expect(description, "Create new project 'New Project'");
    });

    test('ToolRegistry describes add_task correctly', () {
      final description = registry.describeAction('add_task', {'project_id': '123', 'title': 'New Task'});
      expect(description, "Add task 'New Task' to project");
    });

    test('ToolRegistry describes set_item_status correctly', () {
      final completedDesc = registry.describeAction('set_item_status', {'item_id': '1', 'is_completed': true});
      expect(completedDesc, "Mark item as completed");

      final activeDesc = registry.describeAction('set_item_status', {'item_id': '1', 'is_completed': false});
      expect(activeDesc, "Mark item as active");
    });

    test('ProposedAction model creation', () {
      final action = ProposedAction(
        description: 'Test Action',
        toolName: 'test_tool',
        toolArgs: {'arg': 1},
      );

      expect(action.id, isNotEmpty);
      expect(action.description, 'Test Action');
      expect(action.toolName, 'test_tool');
      expect(action.toolArgs['arg'], 1);
    });

    test('ChatMessage model creation', () {
      final msg = ChatMessage(text: 'Hello', isUser: true);
      expect(msg.id, isNotEmpty);
      expect(msg.text, 'Hello');
      expect(msg.isUser, true);
      expect(msg.timestamp, isNotNull);
    });
  });
}




