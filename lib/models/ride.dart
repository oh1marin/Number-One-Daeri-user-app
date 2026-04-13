class Ride {
  final String id;
  final String date;
  final String time;
  final String customerName;
  final String driverName;
  final String pickup;
  final String dropoff;
  final int fare;
  final int discount;
  final int extra;
  final int total;

  Ride({
    required this.id,
    required this.date,
    required this.time,
    required this.customerName,
    required this.driverName,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.discount,
    required this.extra,
    required this.total,
  });

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
        id: json['id'] as String,
        date: json['date'] as String,
        time: json['time'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        driverName: json['driverName'] as String? ?? '',
        pickup: json['pickup'] as String? ?? '',
        dropoff: json['dropoff'] as String? ?? '',
        fare: json['fare'] as int? ?? 0,
        discount: json['discount'] as int? ?? 0,
        extra: json['extra'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'customerName': customerName,
        'driverName': driverName,
        'pickup': pickup,
        'dropoff': dropoff,
        'fare': fare,
        'discount': discount,
        'extra': extra,
        'total': total,
      };
}
