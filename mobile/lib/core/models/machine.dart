class Machine {
  final String id;
  final String name;
  final String status;
  final DateTime lastSeen;

  const Machine({
    required this.id,
    required this.name,
    this.status = 'Healthy',
    required this.lastSeen,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Machine',
      status: json['status'] as String? ?? 'Healthy',
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
