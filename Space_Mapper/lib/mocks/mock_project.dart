import '../models/project.dart';
import '../db/database_project.dart';

mixin MockProject implements Project {
  static List<Project> items = [];

  static List<Project> _defaultItems() {
    return [
      Project(
        0,
        'Sample Project',
        'Sample project summary',
        null,
        null,
        '',
        1,
        '',
      )
    ];
  }

  static Future<void> populateItemsFromDatabase() async {
    try {
      final projects = await ProjectDatabase.instance.FetchAllProjects();

      items = projects.map((project) {
        return Project(
          project.projectId ?? -1,
          project.projectName,
          project.projectDescription ?? "",
          project.externalLink,
          project.internalLink,
          project.projectImageLocation ?? "",
          project.locationSharingMethod,
          project.surveyElementCode,
        );
      }).toList();
    } catch (_) {
      items = _defaultItems();
    }

    if (items.isEmpty) {
      items = _defaultItems();
    }
  }

  static Project fetchFirst() {
    if (items.isEmpty) {
      items = _defaultItems();
      populateItemsFromDatabase();
    }
    if (items.isNotEmpty) {
      return items[0];
    }
    throw Exception('No projects available');
  }

  static Future<List<Project>> fetchAll() async {
    await populateItemsFromDatabase();
    return items;
  }

  static Future<Project> fetchByID(int projectId) async {
    await populateItemsFromDatabase();

    try {
      // Find the project by ID instead of by index
      final project = items.firstWhere((project) => project.id == projectId);
      return project;
    } catch (e) {
      throw Exception('Project with ID $projectId not found');
    }
  }
}
