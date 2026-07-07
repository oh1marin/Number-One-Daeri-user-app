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
  final String status;

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
    this.status = '',
  });

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
        id: (json['id'] ?? '').toString(),
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        customerName: json['customerName'] as String? ?? '',
        driverName: json['driverName'] as String? ?? '',
        pickup: (json['pickup'] ?? json['pickupAddress'] ?? json['address'])?.toString() ?? '',
        dropoff: (json['dropoff'] ?? json['dropoffAddress'] ?? json['destination'])?.toString() ?? '',
        fare: (json['fare'] as num?)?.toInt() ?? 0,
        discount: (json['discount'] as num?)?.toInt() ?? 0,
        extra: (json['extra'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        status: (json['status'] ?? json['rideStatus'] ?? '').toString(),
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
        'status': status,
      };
}
