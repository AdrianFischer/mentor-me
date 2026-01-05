import '../models/models.dart';

abstract class FilePersistenceService {
  Future<List<Project>> loadAllProjects();
  Future<void> saveProject(Project project);
  Future<void> deleteProject(String projectId);
  Stream<List<Project>> watchProjects();
}
