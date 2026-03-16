import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/utils/markdown_parser.dart';
import 'package:flutter_app/providers/filtered_data_providers.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNodeService extends Mock implements NodeService {}

void main() {
  group('Test 13: Project Completion State Toggle Test', () {
    test('Toggling isCompleted serializes correctly into Markdown frontmatter', () {
      final node = Node(
        id: 'proj-1',
        title: 'Completed Project',
        isCompleted: true,
      );

      final markdown = MarkdownParser.nodeToMarkdown(node);
      expect(markdown, contains('is_completed: true'));
      
      final parsedNode = MarkdownParser.parseNode(markdown);
      expect(parsedNode.isCompleted, isTrue);

      final incompleteNode = node.copyWith(isCompleted: false);
      final incompleteMarkdown = MarkdownParser.nodeToMarkdown(incompleteNode);
      expect(incompleteMarkdown, isNot(contains('is_completed: true')));
      
      final parsedIncomplete = MarkdownParser.parseNode(incompleteMarkdown);
      expect(parsedIncomplete.isCompleted, isFalse);
    });

    test('UI providers correctly hide or show based on view filters', () {
      final mockNodeService = MockNodeService();
      
      final rootNodes = [
        Node(id: 'proj-1', title: 'Active Project', isCompleted: false),
        Node(id: 'proj-2', title: 'Completed Project', isCompleted: true),
      ];

      when(() => mockNodeService.getChildren(null)).thenReturn(rootNodes);

      final container = ProviderContainer(
        overrides: [
          nodeServiceProvider.overrideWith((ref) => mockNodeService),
        ],
      );

      // By default, showCompletedProjects is true
      final initialFiltered = container.read(filteredChildrenProvider(null));
      expect(initialFiltered.length, 2);

      // Toggle to hide completed projects
      container.read(taskFilterProvider.notifier).toggleProjects();
      
      // Filter should now hide proj-2
      final hiddenFiltered = container.read(filteredChildrenProvider(null));
      expect(hiddenFiltered.length, 1);
      expect(hiddenFiltered.first.id, 'proj-1');

      container.dispose();
    });
  });
}
