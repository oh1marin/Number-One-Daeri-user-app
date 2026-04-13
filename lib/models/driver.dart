class Driver {
  final String id;
  final String name;
  final String? phone;
  final String? mobile;

  Driver({
    required this.id,
    required this.name,
    this.phone,
    this.mobile,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        mobile: json['mobile'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'mobile': mobile,
      };
}
