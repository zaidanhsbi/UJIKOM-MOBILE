class StudentUser {
  const StudentUser({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.role,
    this.nisn,
    this.username,
    this.schoolName,
  });

  final int id;
  final int schoolId;
  final String name;
  final String role;
  final String? nisn;
  final String? username;
  final String? schoolName;

  /// Mengonversi data JSON pengguna menjadi instance [StudentUser].
  factory StudentUser.fromJson(Map<String, dynamic> json) {
    final school = json['school'] as Map<String, dynamic>?;
    return StudentUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      schoolId: (json['school_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'siswa').toString(),
      nisn: json['nisn']?.toString(),
      username: json['username']?.toString(),
      schoolName: school?['name']?.toString(),
    );
  }

  /// Mengonversi instance [StudentUser] menjadi peta JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'name': name,
        'role': role,
        'nisn': nisn,
        'username': username,
        'school': schoolName != null ? {'name': schoolName} : null,
      };
}
