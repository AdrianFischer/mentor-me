import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/ai_tools/implementations/update_notes_tool.dart';

class MockDataService extends Mock implements DataService {}

void main() {
  late MockDataService mockDataService;

  setUp(() {
    mockDataService = MockDataService();
  });

  group('UpdateNotesTool Tests', () {
    test('UpdateNotesTool calls updateNotes', () async {
      final tool = UpdateNotesTool();
      
      // updateNotes is void, so we verify the call
      when(() => mockDataService.updateNotes(any(), any())).thenReturn(null);

      final result = await tool.execute({
        'item_id': 'item-1',
        'notes': 'New Notes Content',
      }, mockDataService);

      expect(result['result'], 'success');
      expect(result['item_id'], 'item-1');
      verify(() => mockDataService.updateNotes('item-1', 'New Notes Content')).called(1);
    });

    test('UpdateNotesTool returns error when missing parameters', () async {
      final tool = UpdateNotesTool();
      
      final resultNoId = await tool.execute({
        'notes': 'Some notes',
      }, mockDataService);

      expect(resultNoId.containsKey('error'), true);

      final resultNoNotes = await tool.execute({
        'item_id': 'item-1',
      }, mockDataService);

      expect(resultNoNotes.containsKey('error'), true);
    });
  });
}
