import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/services/mcp_client_service.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:flutter_app/providers/ai_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/data_service.dart';

class MockDataService extends Mock implements DataService {}
class MockToolRegistry extends Mock implements ToolRegistry {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('McpClientService Integration', () {
    late ProviderContainer container;
    late MockDataService mockDataService;

    setUp(() {
      mockDataService = MockDataService();
      container = ProviderContainer(overrides: [
         // We can't easily mock the creation inside the provider without more refactoring,
         // but we can check if the provider returns a valid service.
         // For a deeper test, we'd mock the ToolRegistry passed to it.
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('mcpClientServiceProvider creates a service instance', () {
      // This implicitly tests that the dependency graph for McpClientService is valid
      // (it needs toolRegistryProvider, which needs dataServiceProvider)
      // We might need to override dataServiceProvider to avoid actual DB init if it happens in constructor.
      // However, DataService is likely just a class. Let's see if we need to mock it.
      // DataService usually needs Isar, so we SHOULD override it.
      
      // Re-setup with overrides
      container = ProviderContainer(overrides: [
        // Override data service to avoid DB errors
        toolRegistryProvider.overrideWith((ref) => ToolRegistry(mockDataService)),
      ]);

      final service = container.read(mcpClientServiceProvider);
      expect(service, isA<McpClientService>());
      
      // We can't easily test "connectToDartMcp" without side effects (spawning process),
      // so we stop here for the unit/integration test of the provider graph.
      service.dispose();
    });
  });
}
