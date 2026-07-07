import '../api/events_api.dart';
import '../api/notices_api.dart';

/// 서버에 공지·이벤트가 없을 때 앱에 표시할 기본 콘텐츠.
/// BE 시드(prisma/seed.ts)와 문구를 맞춰 두었습니다.
class DefaultNoticesContent {
  DefaultNoticesContent._();

  static const _eventPeriod = '2026.06.01 ~ 2026.12.31';
  static const _eventStart = '2026-06-01';
  static const _eventEnd = '2026-12-31';

  static List<Notice> get notices => [
        Notice(
          id: 'default-notice-open',
          badge: '공지',
          badgeColor: 'bg-red-100 text-red-600',
          title: '일등대리 앱 정식 오픈 안내',
          date: '2026.06.05',
          views: 128,
          content: '''안녕하세요, 일등대리입니다.

스마트폰으로 간편하게 대리운전을 이용하실 수 있는 일등대리 앱이 정식 오픈했습니다.

■ 주요 기능
· 지도에서 출발·도착지 선택 후 바로 호출
· 카드·토스페이·카카오페이 등 다양한 결제
· 마일리지 적립 및 기프티콘 교환
· 친구 추천 이벤트

■ 고객센터
· 전화 접수: 010-2184-8822
· 앱 내 1:1 문의

앞으로도 더 편리한 서비스로 보답하겠습니다.
감사합니다.''',
        ),
        Notice(
          id: 'default-notice-mileage',
          badge: '안내',
          badgeColor: 'bg-blue-100 text-blue-600',
          title: '마일리지 적립 혜택 안내',
          date: '2026.06.05',
          views: 86,
          content: '''일등대리 마일리지 적립 혜택을 안내드립니다.

■ 신규 가입
· 가입 시 10,000P 지급 (대리 호출 시 사용 가능)

■ 이용 적립
· 등록 카드 결제 시 이용요금의 10% 마일리지 적립
· 전화 접수(010-2184-8822) 이용 시에도 10% 적립

■ 마일리지 사용
· 대리 호출 결제 시 마일리지 사용 가능
· 기프티콘 교환몰에서 상품권 교환 가능

※ 적립·사용 조건은 앱 내 마일리지 화면에서 확인해 주세요.''',
        ),
        Notice(
          id: 'default-notice-event',
          badge: '이벤트',
          badgeColor: 'bg-amber-100 text-amber-700',
          title: '2026 친구 추천·신규회원 이벤트',
          date: '2026.06.05',
          views: 214,
          content: '''일등대리 친구 추천 이벤트가 진행 중입니다!

■ 신규 회원
· 가입 시 10,000P 즉시 지급

■ 추천인 혜택
· 친구가 추천인 등록 시 2,000원 적립
· 친구 2명 추천 달성 시 스타벅스 쿠폰 2장
· 친구 5명 추천 달성 시 교촌치킨 세트 쿠폰

■ 참여 방법
1. 앱 메뉴 → 내추천인 등록 / 내추천인 현황
2. 친구에게 앱 설치 후 가입 안내
3. 친구가 가입 후 추천인 전화번호 등록

※ 이벤트 기간 및 상세 조건은 앱 내 이벤트·쿠폰함을 참고해 주세요.''',
          events: [
            NoticeEvent(
              title: '신규 가입 10,000P',
              date: _eventPeriod,
              desc: '일등대리 신규 가입 시 10,000P 마일리지를 드립니다. 대리 호출 결제에 사용할 수 있어요.',
            ),
            NoticeEvent(
              title: '친구 추천 2,000원 적립',
              date: _eventPeriod,
              desc: '친구가 내 전화번호로 추천인 등록 시 2,000원이 적립됩니다. 2명·5명 달성 시 추가 쿠폰도 지급!',
            ),
            NoticeEvent(
              title: '카드 결제 10% 마일리지 적립',
              date: _eventPeriod,
              desc: '등록 카드 또는 앱 결제로 이용 시 이용요금의 10%를 마일리지로 적립해 드립니다.',
            ),
            NoticeEvent(
              title: '기프티콘 교환몰 오픈',
              date: _eventPeriod,
              desc: '적립한 마일리지로 스타벅스·치킨 등 다양한 기프티콘을 교환해 보세요.',
            ),
          ],
        ),
        Notice(
          id: 'default-notice-payment',
          badge: '공지',
          badgeColor: 'bg-red-100 text-red-600',
          title: '토스페이먼츠 결제 연동 안내',
          date: '2026.06.04',
          views: 52,
          content: '''결제 시스템이 토스페이먼츠로 연동되었습니다.

■ 앱 결제
· 카드, 토스페이, 카카오페이 등을 한 화면에서 선택 가능

■ 등록 카드
· 자주 쓰는 카드를 등록해 두면 다음 이용 시 빠르게 결제할 수 있습니다.

■ 안전 결제
· 결제 과정은 토스페이먼츠 보안 환경에서 처리됩니다.

결제 관련 문의는 앱 내 1:1 문의 또는 고객센터(010-2184-8822)로 연락해 주세요.''',
        ),
        Notice(
          id: 'default-notice-guide',
          badge: '안내',
          badgeColor: 'bg-gray-100 text-gray-600',
          title: '대리운전 이용 시 유의사항',
          date: '2026.06.03',
          views: 41,
          content: '''안전하고 원활한 이용을 위해 아래 사항을 확인해 주세요.

■ 호출 전
· 출발지·도착지를 정확히 입력해 주세요.
· 차량 위치·주차 상태를 기사님께 알려 주시면 원활합니다.

■ 이용 중
· 기사님과의 연락은 앱 또는 등록된 연락처를 이용해 주세요.
· 음주운전 대신 대리운전을 이용해 주세요.

■ 결제·마일리지
· 결제 완료 후 이용내역·영수증은 앱에서 확인할 수 있습니다.
· 마일리지·쿠폰 사용 조건은 각 화면 안내를 참고해 주세요.

불편 사항은 앱 내 불편신고 또는 1:1 문의로 접수해 주세요.''',
        ),
      ];

  static List<EventItem> get events {
    final out = <EventItem>[];
    var idx = 0;
    for (final notice in notices) {
      for (final e in notice.events) {
        if (e.title.trim().isEmpty && (e.desc ?? '').trim().isEmpty) continue;
        out.add(
          EventItem(
            id: 'default-event-$idx',
            title: e.title.trim().isEmpty ? '이벤트' : e.title.trim(),
            imageUrl: e.imageUrl,
            startAt: _eventStart,
            endAt: _eventEnd,
            url: null,
            date: e.date,
            content: e.desc,
          ),
        );
        idx++;
      }
    }
    return out;
  }
}
