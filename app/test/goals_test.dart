import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/models.dart';  // For TaskGoal
import 'package:flutter_app/services/node_service.dart';
import 'helpers/fake_storage_repository.dart';

void main() {
  group('Goal Tracking Tests', () {
    late NodeService nodeService;
    late FakeStorageRepository repository;

    setUp(() async {
      repository = FakeStorageRepository();
      nodeService = NodeService(repository);
      await nodeService.initData();
    });

    test('Set and update Numeric Goal', () async {
      // 1. Create a root node (project) and a child node (task)
      final pid = await nodeService.addChild(null, "Test Project");
      final tid = (await nodeService.addChild(pid, "Save Money"))!;

      // 2. Set Goal
      final goal = TaskGoal.numeric(target: 1000, unit: "\$");
      nodeService.setGoal(tid, goal);

      // Verify
      var node = nodeService.findNode(tid)!;
      expect(node.goal, isNotNull);
      node.goal!.map(
        numeric: (n) {
          expect(n.target, 1000);
          expect(n.current, 0);
          expect(n.unit, "\$");
        },
        habit: (_) => fail("Should be numeric"),
      );

      // 3. Record Progress
      nodeService.recordGoalProgress(tid, amount: 200, note: "First deposit");

      // Verify
      node = nodeService.findNode(tid)!;
      node.goal!.map(
        numeric: (n) {
          expect(n.current, 200);
          expect(n.history.length, 1);
          expect(n.history.first.amount, 200);
          expect(n.history.first.note, "First deposit");
        },
        habit: (_) => fail("Should be numeric"),
      );

      // 4. Record more progress
      nodeService.recordGoalProgress(tid, amount: 50);

      // Verify
      node = nodeService.findNode(tid)!;
      node.goal!.map(
        numeric: (n) {
          expect(n.current, 250);
          expect(n.history.length, 2);
        },
        habit: (_) => fail("Should be numeric"),
      );
    });

    test('Set and update Habit Goal', () async {
      // 1. Create a root node (project) and a child node (task)
      final pid = await nodeService.addChild(null, "Habits");
      final tid = (await nodeService.addChild(pid, "Exercise"))!;

      // 2. Set Goal
      final goal = TaskGoal.habit(targetFrequency: 0.8); // 80%
      nodeService.setGoal(tid, goal);

      // Verify
      var node = nodeService.findNode(tid)!;
      node.goal!.map(
        numeric: (_) => fail("Should be habit"),
        habit: (h) {
          expect(h.targetFrequency, 0.8);
          expect(h.history, isEmpty);
        },
      );

      // 3. Record Success
      nodeService.recordGoalProgress(tid, isSuccess: true, note: "Ran 5km");

      // Verify
      node = nodeService.findNode(tid)!;
      node.goal!.map(
        numeric: (_) => fail("Should be habit"),
        habit: (h) {
          expect(h.history.length, 1);
          expect(h.history.first.isSuccess, true);
          expect(h.history.first.note, "Ran 5km");
        },
      );
    });
  });
}
