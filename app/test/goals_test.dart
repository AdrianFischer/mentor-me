import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/services/data_service.dart';
import 'helpers/fake_storage_repository.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';

class FakeMarkdownPersistence implements MarkdownPersistenceService {
  @override
  bool get isEnabled => true;
  @override
  Future<void> saveProject(Project project) async {}
  @override
  Future<void> deleteProject(Project project) async {}
}

void main() {
  group('Goal Tracking Tests', () {
    late DataService dataService;
    late FakeStorageRepository repository;

    setUp(() async {
      repository = FakeStorageRepository();
      dataService = DataService(repository, FakeMarkdownPersistence());
      await dataService.initData();
    });

    test('Set and update Numeric Goal', () async {
      // 1. Create Project and Task
      final pid = await dataService.addProject("Test Project");
      final tid = (await dataService.addTask(pid, "Save Money"))!;

      // 2. Set Goal
      final goal = TaskGoal.numeric(target: 1000, unit: "\$");
      dataService.setTaskGoal(tid, goal);

      // Verify
      var task = dataService.projects.first.tasks.first;
      expect(task.goal, isNotNull);
      task.goal!.map(
        numeric: (n) {
          expect(n.target, 1000);
          expect(n.current, 0);
          expect(n.unit, "\$");
        },
        habit: (_) => fail("Should be numeric"),
      );

      // 3. Record Progress
      dataService.recordGoalProgress(tid, amount: 200, note: "First deposit");
      
      // Verify
      task = dataService.projects.first.tasks.first;
      task.goal!.map(
        numeric: (n) {
          expect(n.current, 200);
          expect(n.history.length, 1);
          expect(n.history.first.amount, 200);
          expect(n.history.first.note, "First deposit");
        },
        habit: (_) => fail("Should be numeric"),
      );

      // 4. Record more progress
      dataService.recordGoalProgress(tid, amount: 50);

      // Verify
      task = dataService.projects.first.tasks.first;
      task.goal!.map(
        numeric: (n) {
          expect(n.current, 250);
          expect(n.history.length, 2);
        },
        habit: (_) => fail("Should be numeric"),
      );
    });

    test('Set and update Habit Goal', () async {
      // 1. Create Project and Task
      final pid = await dataService.addProject("Habits");
      final tid = (await dataService.addTask(pid, "Exercise"))!;

      // 2. Set Goal
      final goal = TaskGoal.habit(targetFrequency: 0.8); // 80%
      dataService.setTaskGoal(tid, goal);

      // Verify
      var task = dataService.projects.first.tasks.first;
      task.goal!.map(
        numeric: (_) => fail("Should be habit"),
        habit: (h) {
          expect(h.targetFrequency, 0.8);
          expect(h.history, isEmpty);
        },
      );

      // 3. Record Success
      dataService.recordGoalProgress(tid, isSuccess: true, note: "Ran 5km");

      // Verify
      task = dataService.projects.first.tasks.first;
      task.goal!.map(
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
