class StudentModel {
  final String id;
  final String name;
  final int age;
  final String className;
  final String? teacherId;
  final String? parentId;
  final String? notes;
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.age,
    required this.className,
    this.teacherId,
    this.parentId,
    this.notes,
    required this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      className: json['class_name'],
      teacherId: json['teacher_id'],
      parentId: json['parent_id'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
