/// 배차/운행 상태 표시 (푸시 알림과 동일 규칙)
class RideStatusUi {
  RideStatusUi._();

  static String normalize(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'driver_assigned':
        return 'assigned';
      case 'driver_arrived':
      case 'arrived':
      case 'at_pickup':
      case 'pickup_arrived':
        return 'arrived_pickup';
      case 'start':
      case 'in_progress':
      case 'driving':
        return 'on_trip';
      case 'finish':
        return 'completed';
      default:
        return s;
    }
  }

  static bool isTerminal(String status) {
    final s = normalize(status);
    return s == 'completed' || s == 'cancelled' || s == 'canceled';
  }

  static String title(String status) {
    switch (normalize(status)) {
      case 'requested':
      case 'created':
      case 'pending':
        return '호출 접수';
      case 'matching':
        return '기사 배정 중';
      case 'assigned':
      case 'accepted':
        return '기사 배정 완료';
      case 'arriving':
        return '기사 이동 중';
      case 'arrived_pickup':
        return '출발지 도착';
      case 'picked_up':
      case 'on_trip':
        return '운행 중';
      case 'completed':
        return '운행 완료';
      case 'cancelled':
      case 'canceled':
        return '호출 취소';
      default:
        return '배차 진행 중';
    }
  }

  static String subtitle(String status, {String driverName = ''}) {
    final who = driverName.trim().isNotEmpty ? '$driverName 기사님' : '기사님';
    switch (normalize(status)) {
      case 'requested':
      case 'created':
      case 'pending':
        return '호출이 접수되었습니다. 곧 기사님을 찾습니다.';
      case 'matching':
        return '가까운 $who을(를) 찾고 있어요.';
      case 'assigned':
      case 'accepted':
        return '$who이(가) 배정되었습니다.';
      case 'arriving':
        return '$who이(가) 출발지로 이동 중입니다.';
      case 'arrived_pickup':
        return '$who이(가) 출발지에 도착했습니다.';
      case 'picked_up':
      case 'on_trip':
        return '안전하게 운행 중입니다.';
      case 'completed':
        return '이용해 주셔서 감사합니다.';
      case 'cancelled':
      case 'canceled':
        return '호출이 취소되었습니다.';
      default:
        return '상태를 확인하고 있어요.';
    }
  }

  /// 타임라인 단계 (왼쪽부터 진행)
  static const timelineSteps = [
    ('requested', '접수'),
    ('matching', '배정중'),
    ('assigned', '배정완료'),
    ('on_trip', '운행중'),
    ('completed', '완료'),
  ];

  static int timelineIndex(String status) {
    final s = normalize(status);
    if (s == 'cancelled' || s == 'canceled') return -1;
    if (s == 'requested' || s == 'created' || s == 'pending') return 0;
    if (s == 'matching') return 1;
    if (s == 'assigned' || s == 'accepted' || s == 'arriving' || s == 'arrived_pickup') {
      return 2;
    }
    if (s == 'picked_up' || s == 'on_trip') return 3;
    if (s == 'completed') return 4;
    return 0;
  }
}
