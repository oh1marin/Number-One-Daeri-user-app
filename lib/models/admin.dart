class Admin {
  final String id;
  final String email;
  final String name;

  Admin({
    required this.id,
    required this.email,
    required this.name,
  });

  factory Admin.fromJson(Map<String, dynamic> json) => Admin(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
      };
}
