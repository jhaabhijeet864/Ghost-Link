class Workspace {
  final String id;
  final String name;
  final String path;
  final String branch;
  final int modifiedFiles;
  final int failingTests;
  final int activeSessions;
  final String machineId;
  final String status;

  const Workspace({
    required this.id,
    required this.name,
    required this.path,
    required this.branch,
    this.modifiedFiles = 0,
    this.failingTests = 0,
    this.activeSessions = 0,
    required this.machineId,
    this.status = 'Healthy',
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Workspace',
      path: json['path'] as String? ?? '',
      branch: json['branch'] as String? ?? 'main',
      modifiedFiles: json['modifiedFiles'] as int? ?? 0,
      failingTests: json['failingTests'] as int? ?? 0,
      activeSessions: json['activeSessions'] as int? ?? 0,
      machineId: json['machineId'] as String? ?? '',
      status: json['status'] as String? ?? 'Healthy',
    );
  }
}
