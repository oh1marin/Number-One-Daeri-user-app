/// 대리호출 시 선택 옵션 (오토/스틱, 대리/탁송, 퀵보드, 차량종류)
class CallOptions {
  const CallOptions({
    required this.transmission,
    required this.serviceType,
    required this.quickBoard,
    required this.vehicleType,
  });

  final String transmission;  // 'auto' | 'stick'
  final String serviceType;   // 'daeri' | 'taksong'
  final String quickBoard;    // 'possible' | 'impossible'
  final String vehicleType;   // 'sedan' | '9seater' | '12seater' | 'cargo1t'

  Map<String, dynamic> toJson() => {
        'transmission': transmission,
        'serviceType': serviceType,
        'quickBoard': quickBoard,
        'vehicleType': vehicleType,
      };
}
