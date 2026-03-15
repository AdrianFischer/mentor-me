import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/ai_tools/ai_tool.dart';
import 'package:flutter_app/ai_tools/implementations/update_notes_tool.dart';

class MockNodeService extends Mock implements NodeService {}
class MockDataService extends Mock implements DataService {}

void main() {
  late MockNodeService mockNodeService;
  late MockDataService mockDataService;
  late ToolContext toolContext;

  setUp(() {
    mockNodeService = MockNodeService();
    mockDataService = MockDataService();
    toolContext = ToolContext(mockNodeService, mockDataService);
  });

  group('UpdateNotesTool Tests', () {
    test('UpdateNotesTool calls updateNotes', () async {
      final tool = UpdateNotesTool();

      when(() => mockNodeService.updateNotes(any(), any())).thenReturn(null);

      final result = await tool.execute({
        'item_id': 'item-1',
        'notes': 'New Notes Content',
      }, toolContext);

      expect(result['result'], 'success');
      expect(result['item_id'], 'item-1');
      verify(() => mockNodeService.updateNotes('item-1', 'New Notes Content')).called(1);
    });

    test('UpdateNotesTool returns error when missing parameters', () async {
      final tool = UpdateNotesTool();

      final resultNoId = await tool.execute({
        'notes': 'Some notes',
      }, toolContext);

      expect(resultNoId.containsKey('error'), true);

      final resultNoNotes = await tool.execute({
        'item_id': 'item-1',
      }, toolContext);

      expect(resultNoNotes.containsKey('error'), true);
    });
  });
}
