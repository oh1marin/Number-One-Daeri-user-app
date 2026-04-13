class Customer {
  final String id;
  final int no;
  final String name;
  final String? phone;
  final String? mobile;
  final String category;

  Customer({
    required this.id,
    required this.no,
    required this.name,
    this.phone,
    this.mobile,
    required this.category,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        no: json['no'] as int? ?? 0,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        mobile: json['mobile'] as String?,
        category: json['category'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'no': no,
        'name': name,
        'phone': phone,
        'mobile': mobile,
        'category': category,
      };
}
