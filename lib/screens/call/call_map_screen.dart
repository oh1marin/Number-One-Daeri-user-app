import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/card_payments_api.dart';
import '../../api/cards_api.dart';
import '../../api/geocode_api.dart';
import '../../api/mileage_api.dart';
import '../../api/rides_call_api.dart';
import '../../api/rides_estimate_api.dart';
import '../../config/kakao_config.dart';
import '../../models/call_options.dart';
import 'call_options_screen.dart';
import '../../services/biometric_payment_service.dart';
import '../../services/kakao_local_service.dart';
import '../../utils/idempotency.dart';
import '../../utils/app_snackbar.dart';
import '../../theme/app_theme.dart';
import '../../widgets/map_location_pin.dart';
import '../card/card_screen.dart';
import '../payment/payment_screen.dart';
import 'destination_search_screen.dart';
import 'package:gap/gap.dart';

const LatLng _kSeoul = LatLng(latitude: 37.5665, longitude: 126.9780);

/// 지도 오버레이 핀 — 출발/도착 구분용 빨강 톤
const Color _kPinDepartureRed = Color(0xFFE53935);
const Color _kPinDestinationRed = Color(0xFFC62828);

/// 위경도 → 화면 픽셀 변환 (Web Mercator, toScreenPoint 대체)
Offset _latLngToScreen(
  double lat,
  double lng,
  double centerLat,
  double centerLng,
  int zoomLevel,
  double width,
  double height,
) {
  final worldSize = 256.0 * math.pow(2, zoomLevel);
  double latToY(double latitude) {
    final latRad = latitude * math.pi / 180;
    final y = math.log(math.tan(math.pi / 4 + latRad / 2));
    return (1 - y / math.pi) / 2 * worldSize;
  }

  final centerX = (centerLng + 180) / 360 * worldSize;
  final centerY = latToY(centerLat);
  final pointX = (lng + 180) / 360 * worldSize;
  final pointY = latToY(lat);
  return Offset(
    width / 2 + (pointX - centerX),
    height / 2 + (pointY - centerY),
  );
}

enum FareType { premium, fast, normal }

enum PaymentMethod { cash, mileage, registeredCard, appPayment }

/// 앱결제 내 세부 수단 (카카오페이 / 토스)
enum AppPaymentMethod { kakaopay, toss }

enum _MapFocus { departure, destination }

/// 24시간 앱 접수 - 대리호출
class CallMapScreen extends StatefulWidget {
  const CallMapScreen({super.key, this.options});

  final CallOptions? options;

  @override
  State<CallMapScreen> createState() => _CallMapScreenState();
}

class _CallMapScreenState extends State<CallMapScreen> {
  KakaoMapController? _mapController;
  LatLng _departure = _kSeoul;
  PlaceSearchResult? _destination;
  String _departureAddr = '위치 조회 중...';
  bool _kakaoOk = false;
  bool _isLoading = true;
  FareType _selectedFare = FareType.normal;
  PaymentMethod _selectedPayment = PaymentMethod.cash;

  EstimateResult? _estimate;
  bool _isEstimateLoading = false;
  List<RegisteredCard> _savedCards = [];
  bool _biometricSupported = false;

  double _mapWidth = 400;
  double _mapHeight = 400;
  int _lockedZoomLevel = 17;
  LatLng _cameraCenter = _kSeoul;
  StreamSubscription<CameraMoveEndEvent>? _cameraSub;
  bool _isProgrammaticMove = false;
  _MapFocus _mapFocus = _MapFocus.departure;
  bool _focusMoveInProgress = false;
  bool _isDetailEditMode = false;
  _MapFocus? _detailEditTarget;

  bool _isSubmittingCall = false;
  String? _clientCallIdInFlight;

  @override
  void initState() {
    super.initState();
    _kakaoOk = kakaoMapApiKey != 'YOUR_KAKAO_NATIVE_APP_KEY';
    _loadLocationFast();
  }

  Future<void> _refreshToGps() async {
    if (_focusMoveInProgress) return;
    _focusMoveInProgress = true;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final target = LatLng(latitude: pos.latitude, longitude: pos.longitude);
      final addr = await GeocodeApi.reverse(target.latitude, target.longitude);
      if (!mounted) return;
      setState(() {
        _departure = target;
        _departureAddr = addr != null ? '현재위치: $addr' : '현재 위치';
      });
      _cameraCenter = target;
      _lockedZoomLevel = 17;
      _isProgrammaticMove = true;
      await _mapController?.moveCamera(
        cameraUpdate: CameraUpdate(position: target, zoomLevel: 17),
        animation: const CameraAnimation(duration: 0, autoElevation: true, isConsecutive: false),
      );
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 200));
    _focusMoveInProgress = false;
    if (mounted) {
      setState(() {});
      if (_destination != null) _fetchEstimate();
    }
  }

  Future<void> _loadLocationFast() async {
    setState(() {
      _isLoading = false;
      _departureAddr = '위치 조회 중...';
    });
    try {
      if (await Geolocator.checkPermission() == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() => _departureAddr = '위치 서비스를 켜주세요');
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final target = LatLng(latitude: pos.latitude, longitude: pos.longitude);
      final addr = await GeocodeApi.reverse(target.latitude, target.longitude);
      if (!mounted) return;
      setState(() {
        _departure = target;
        _departureAddr = addr != null ? '현재위치: $addr' : '현재 위치';
      });
      _cameraCenter = target;
      _lockedZoomLevel = 17;
      if (_destination != null) {
        await _updateMapAndOverlays();
      } else {
        _isProgrammaticMove = true;
        await _mapController?.moveCamera(
          cameraUpdate: CameraUpdate(position: target, zoomLevel: 17),
          animation: const CameraAnimation(duration: 0, autoElevation: true, isConsecutive: false),
        );
        _isProgrammaticMove = false;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _departureAddr = '위치 조회 실패');
      }
    }
  }

  double get _distanceKm {
    if (_estimate != null) return _estimate!.distanceKm;
    if (_destination == null) return 0;
    return Geolocator.distanceBetween(
      _departure.latitude,
      _departure.longitude,
      _destination!.lat,
      _destination!.lng,
    ) / 1000;
  }

  int get _fareNormal => _estimate?.normal ?? 0;
  int get _fareFast => _estimate?.fast ?? 0;
  int get _farePremium => _estimate?.premium ?? 0;

  String get _fareTypeString {
    switch (_selectedFare) {
      case FareType.premium:
        return 'premium';
      case FareType.fast:
        return 'fast';
      case FareType.normal:
        return 'normal';
    }
  }

  int get _selectedFareAmount {
    switch (_selectedFare) {
      case FareType.premium:
        return _farePremium;
      case FareType.fast:
        return _fareFast;
      case FareType.normal:
        return _fareNormal;
    }
  }

  Offset _computeDepScreen() => _latLngToScreen(
        _departure.latitude,
        _departure.longitude,
        _cameraCenter.latitude,
        _cameraCenter.longitude,
        _lockedZoomLevel,
        _mapWidth,
        _mapHeight,
      );

  Offset? _computeDestScreen() {
    if (_destination == null) return null;
    return _latLngToScreen(
      _destination!.lat,
      _destination!.lng,
      _cameraCenter.latitude,
      _cameraCenter.longitude,
      _lockedZoomLevel,
      _mapWidth,
      _mapHeight,
    );
  }


  LatLng get _focusedPinPosition =>
      _mapFocus == _MapFocus.departure
          ? _departure
          : (_destination != null
              ? LatLng(latitude: _destination!.lat, longitude: _destination!.lng)
              : _departure);

  Future<void> _centerOnFocusedPin() async {
    if (_mapController == null) return;
    _cameraCenter = _focusedPinPosition;
    _lockedZoomLevel = 17;
    _isProgrammaticMove = true;
    await _mapController!.moveCamera(
      cameraUpdate: CameraUpdate(position: _focusedPinPosition, zoomLevel: 17),
      animation: const CameraAnimation(duration: 60, autoElevation: true, isConsecutive: false),
    );
    _isProgrammaticMove = false;
  }

  Future<void> _fitBoundsIfDestination() async {
    if (_destination == null || _mapController == null) return;
    _mapFocus = _MapFocus.destination;
    await _centerOnFocusedPin();
  }

  Future<void> _updateMapAndOverlays() async {
    if (_destination != null) {
      await _fitBoundsIfDestination();
    } else {
      _mapFocus = _MapFocus.departure;
      if (_mapController != null) await _centerOnFocusedPin();
    }
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) setState(() {});
    _fetchEstimate();
  }

  Future<void> _fetchEstimate() async {
    if (_destination == null) {
      setState(() {
        _estimate = null;
        _isEstimateLoading = false;
        _savedCards = [];
      });
      return;
    }
    setState(() => _isEstimateLoading = true);
    try {
      final result = await RidesEstimateApi.estimate(
        originLatitude: _departure.latitude,
        originLongitude: _departure.longitude,
        destinationLatitude: _destination!.lat,
        destinationLongitude: _destination!.lng,
      );
      final cards = await CardsApi.getList();
      final bioSupported = await BiometricPaymentService.isSupported;
      if (mounted) {
        setState(() {
          _estimate = result;
          _savedCards = cards;
          _biometricSupported = bioSupported;
          _isEstimateLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _estimate = null;
          _savedCards = [];
          _biometricSupported = false;
          _isEstimateLoading = false;
        });
      }
    }
  }

  void _onMapCreated(KakaoMapController c) async {
    _mapController = c;
    _cameraCenter = _departure;
    _lockedZoomLevel = 17;
    _cameraSub = c.onCameraMoveEndStream.listen((e) async {
      if (_isProgrammaticMove || _focusMoveInProgress) return;
      if (_isDetailEditMode) {
        _cameraCenter = LatLng(latitude: e.latitude, longitude: e.longitude);
        if (mounted) setState(() {});
        return;
      }
      final fp = _focusedPinPosition;
      final moved = Geolocator.distanceBetween(
        e.latitude, e.longitude, fp.latitude, fp.longitude,
      );
      if (moved < 2) return;
      _cameraCenter = fp;
      _isProgrammaticMove = true;
      await c.moveCamera(
        cameraUpdate: CameraUpdate(position: fp, zoomLevel: _lockedZoomLevel),
        animation: const CameraAnimation(duration: 60, autoElevation: true, isConsecutive: false),
      );
      _isProgrammaticMove = false;
      if (mounted) setState(() {});
    });
    _isProgrammaticMove = true;
    c.moveCamera(
      cameraUpdate: CameraUpdate(position: _departure, zoomLevel: 17),
      animation: const CameraAnimation(duration: 80, autoElevation: true, isConsecutive: false),
    ).then((_) async {
      _isProgrammaticMove = false;
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) setState(() {});
    });
  }

  Future<void> _onMapFocusChanged(_MapFocus focus) async {
    if (_focusMoveInProgress) return;
    if (focus == _MapFocus.destination && _destination == null) return;
    final c = _mapController;
    if (c == null) return;

    _focusMoveInProgress = true;
    _mapFocus = focus;
    _isProgrammaticMove = true;

    final target = focus == _MapFocus.departure
        ? _departure
        : LatLng(latitude: _destination!.lat, longitude: _destination!.lng);

    _cameraCenter = target;
    _lockedZoomLevel = 17;

    await c.moveCamera(
      cameraUpdate: CameraUpdate(position: target, zoomLevel: 17),
      animation: const CameraAnimation(duration: 60, autoElevation: true, isConsecutive: false),
    );

    await Future.delayed(const Duration(milliseconds: 40));
    _isProgrammaticMove = false;
    _focusMoveInProgress = false;
    if (mounted) setState(() {});
  }

  Future<void> _enforceZoomLock() async {
    final c = _mapController;
    if (c == null) return;
    _isProgrammaticMove = true;
    await c.moveCamera(
      cameraUpdate: CameraUpdate(position: _cameraCenter, zoomLevel: _lockedZoomLevel),
      animation: const CameraAnimation(duration: 60, autoElevation: true, isConsecutive: false),
    );
    _isProgrammaticMove = false;
  }

  @override
  void dispose() {
    _cameraSub?.cancel();
    super.dispose();
  }

  Future<void> _openDepartureSearch() async {
    final r = await Navigator.push<PlaceSearchResult>(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationSearchScreen(
          title: '출발지 선택',
          buttonLabel: '출발',
          originLat: _departure.latitude,
          originLng: _departure.longitude,
          onSelect: (_) {},
        ),
      ),
    );
    if (r != null && mounted) {
      setState(() {
        _departure = LatLng(latitude: r.lat, longitude: r.lng);
        _departureAddr = r.name;
      });
      await _updateMapAndOverlays();
      if (_destination != null && mounted) {
        _mapFocus = _MapFocus.departure;
        await _centerOnFocusedPin();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _openDestinationSearch() async {
    final r = await Navigator.push<PlaceSearchResult>(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationSearchScreen(
          originLat: _departure.latitude,
          originLng: _departure.longitude,
          onSelect: (_) {},
        ),
      ),
    );
    if (r != null && mounted) {
      setState(() => _destination = r);
      await _updateMapAndOverlays();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('대리호출', style: TextStyle(color: Colors.black87, fontSize: 18)),
      ),
      body: _isDetailEditMode
          ? _buildMapArea(allowTouch: true)
          : Column(
              children: [
                Expanded(
                  flex: _destination != null ? 3 : 6,
                  child: _buildMapArea(),
                ),
                Expanded(
                  flex: _destination != null ? 7 : 4,
                  child: _buildBottomPanel(),
                ),
              ],
            ),
      bottomNavigationBar: _isDetailEditMode ? _buildDetailEditBottomBar(context) : null,
    );
  }

  Future<void> _openDetailEdit() async {
    _detailEditTarget = _mapFocus;
    _cameraCenter = _focusedPinPosition;
    setState(() => _isDetailEditMode = true);
    final c = _mapController;
    if (c != null) {
      _isProgrammaticMove = true;
      await c.moveCamera(
        cameraUpdate: CameraUpdate(position: _focusedPinPosition, zoomLevel: _lockedZoomLevel),
        animation: const CameraAnimation(duration: 100, autoElevation: true, isConsecutive: false),
      );
      _isProgrammaticMove = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _confirmDetailEdit() async {
    final target = _detailEditTarget;
    if (target == null) return;
    final lat = _cameraCenter.latitude;
    final lng = _cameraCenter.longitude;
    final addr = await GeocodeApi.reverse(lat, lng);

    if (!mounted) return;
    if (target == _MapFocus.departure) {
      setState(() {
        _departure = LatLng(latitude: lat, longitude: lng);
        _departureAddr = (addr != null && addr.isNotEmpty) ? addr : '지도에서 선택';
        _isDetailEditMode = false;
        _detailEditTarget = null;
      });
    } else if (target == _MapFocus.destination) {
      final label = (addr != null && addr.isNotEmpty) ? addr : '지도에서 선택';
      setState(() {
        _destination = PlaceSearchResult(
          name: label,
          address: addr ?? '',
          lat: lat,
          lng: lng,
          distance: null,
        );
        _isDetailEditMode = false;
        _detailEditTarget = null;
      });
    }
    if (_destination != null) _fetchEstimate();
  }

  /// `body`의 `Column`+`Expanded` 밖에 두어, 버튼 줄 높이와 지도 영역이 서로 깎이며 나는 RenderFlex 오버플로우를 막음
  Widget _buildDetailEditBottomBar(BuildContext context) {
    final isDeparture = _detailEditTarget == _MapFocus.departure;
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _isDetailEditMode = false;
                    _detailEditTarget = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  child: const Text('닫기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => _confirmDetailEdit(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  child: Text(
                    isDeparture ? '이 위치로 출발지' : '이 위치로 도착지',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapArea({bool allowTouch = false}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue));
    }
    if (!_kakaoOk) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Text('지도를 불러올 수 없습니다.')),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _mapWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 400;
        _mapHeight = constraints.maxHeight > 0 ? constraints.maxHeight : 400;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
        final depScreen = _computeDepScreen();
        final destScreen = _computeDestScreen();
        final center = Offset(_mapWidth / 2, _mapHeight / 2);
        final focusForPin = (allowTouch && _isDetailEditMode && _detailEditTarget != null)
            ? _detailEditTarget!
            : _mapFocus;
        final showFocusedAtCenter = !allowTouch || _isDetailEditMode;
        final startPin = showFocusedAtCenter && focusForPin == _MapFocus.departure ? center : depScreen;
        final endPin = destScreen != null
            ? (showFocusedAtCenter && focusForPin == _MapFocus.destination ? center : destScreen)
            : null;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            KakaoMap(
              initialPosition: _departure,
              initialLevel: 17,
              onMapCreated: _onMapCreated,
            ),
            if (showFocusedAtCenter) ...[
              _MapPinOverlay(
                point: center,
                label: focusForPin == _MapFocus.departure ? '출발' : '도착',
                color: focusForPin == _MapFocus.departure ? _kPinDepartureRed : _kPinDestinationRed,
              ),
              if (focusForPin == _MapFocus.departure && destScreen != null)
                _MapPinOverlay(point: destScreen, label: '도착', color: _kPinDestinationRed),
              if (focusForPin == _MapFocus.destination)
                _MapPinOverlay(point: depScreen, label: '출발', color: _kPinDepartureRed),
            ] else ...[
              _MapPinOverlay(point: depScreen, label: '출발', color: _kPinDepartureRed),
              if (destScreen != null)
                _MapPinOverlay(point: destScreen, label: '도착', color: _kPinDestinationRed),
            ],
            if (endPin != null && !allowTouch)
              _RouteLineOverlay(start: startPin, end: endPin),
            if (!allowTouch) ...[
              Positioned(
                right: 12,
                top: 12,
                child: _MapFocusButtons(
                  focus: _mapFocus,
                  hasDestination: _destination != null,
                  onFocusChanged: _onMapFocusChanged,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _openDetailEdit(),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_location_alt, size: 18, color: AppTheme.accentBlue),
                          const SizedBox(width: 6),
                          Text('위치 상세수정', style: TextStyle(fontSize: 13, color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AddressRow(
                label: '출발',
                text: _departureAddr,
                onTap: _openDepartureSearch,
                onRefresh: _refreshToGps,
              ),
              const Gap(8),
              Text(
                '어디로 모실까요?',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              InkWell(
                onTap: _openDestinationSearch,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _destination != null ? AppTheme.accentBlue.withValues(alpha: 0.5) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _destination?.name ?? '도착 : 어디로 가세요?',
                          style: TextStyle(
                            fontSize: 14,
                            color: _destination != null ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('경유', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_destination != null) ...[
                const Gap(8),
                Text(
                  '${_distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Gap(6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FareChip(
                        icon: PhosphorIconsFill.car,
                        label: '프리미엄',
                        fare: _farePremium,
                        isLoading: _isEstimateLoading,
                        color: Colors.red,
                        selected: _selectedFare == FareType.premium,
                        onTap: () => setState(() => _selectedFare = FareType.premium),
                      ),
                      const Gap(8),
                      _FareChip(
                        icon: PhosphorIconsFill.car,
                        label: '빠른 호출',
                        fare: _fareFast,
                        isLoading: _isEstimateLoading,
                        isBest: true,
                        selected: _selectedFare == FareType.fast,
                        onTap: () => setState(() => _selectedFare = FareType.fast),
                      ),
                      const Gap(8),
                      _FareChip(
                        icon: PhosphorIconsFill.car,
                        label: '일반',
                        fare: _fareNormal,
                        isLoading: _isEstimateLoading,
                        selected: _selectedFare == FareType.normal,
                        onTap: () => setState(() => _selectedFare = FareType.normal),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    _PayChip(
                      icon: PhosphorIconsFill.currencyDollar,
                      label: '현금',
                      selected: _selectedPayment == PaymentMethod.cash,
                      onTap: () => setState(() => _selectedPayment = PaymentMethod.cash),
                    ),
                    const Gap(8),
                    _PayChip(
                      icon: PhosphorIconsFill.coins,
                      label: '마일',
                      selected: _selectedPayment == PaymentMethod.mileage,
                      onTap: () => setState(() => _selectedPayment = PaymentMethod.mileage),
                    ),
                    const Gap(8),
                    _PayChip(
                      icon: PhosphorIconsFill.creditCard,
                      label: '등록 카드',
                      selected: _selectedPayment == PaymentMethod.registeredCard,
                      onTap: () => setState(() => _selectedPayment = PaymentMethod.registeredCard),
                    ),
                    const Gap(8),
                    _PayChip(
                      icon: PhosphorIconsFill.deviceMobile,
                      label: '앱결제',
                      selected: _selectedPayment == PaymentMethod.appPayment,
                      onTap: () => setState(() => _selectedPayment = PaymentMethod.appPayment),
                    ),
                  ],
                ),
                const Gap(8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isEstimateLoading ? null : () => _openCallOptionsThenConfirm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isEstimateLoading ? '요금 계산 중...' : '대리호출 (${_fmt(_selectedFareAmount)}원)',
                    ),
                  ),
                ),
              ] else ...[
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _openCallOptionsThenConfirm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('대리호출'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  /// 등록 카드 선택 시 카드 목록 bottom sheet
  Future<RegisteredCard?> _showRegisteredCardChoice(BuildContext context) async {
    final cards = await CardsApi.getList();
    if (!context.mounted) return null;
    if (cards.isEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('카드 등록 필요'),
          content: const Text('등록된 카드가 없습니다.\n카드 등록 화면으로 이동하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('카드 등록'),
            ),
          ],
        ),
      );
      if (go == true && context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardScreen()),
        );
      }
      return null;
    }
    return showModalBottomSheet<RegisteredCard>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '결제할 카드 선택',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Gap(16),
              ...cards.map(
                (c) => ListTile(
                  leading: const PhosphorIcon(PhosphorIconsFill.creditCard, color: AppTheme.accentBlue),
                  title: Text(c.cardName),
                  subtitle: c.last4Digits != null ? Text('****${c.last4Digits}') : null,
                  onTap: () => Navigator.pop(context, c),
                ),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  /// 결제 성공 후 — "다음부터 인증 사용" 제안 (카드 저장 시 + 생체인증 지원 시)
  Future<void> _maybeShowBiometricEnableDialog(BuildContext context) async {
    final supported = await BiometricPaymentService.isSupported;
    final alreadyEnabled = await BiometricPaymentService.useBiometricForAppPayment;
    if (!supported || alreadyEnabled || !context.mounted) return;

    final typeName = await BiometricPaymentService.biometricTypeName;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('간편 결제 설정'),
        content: Text(
          '다음 결제부터 $typeName 인증만으로 결제창 없이 바로 결제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await BiometricPaymentService.authenticate(
                reason: '$typeName으로 등록을 확인합니다',
              );
              if (!context.mounted) return;
              if (ok) {
                await BiometricPaymentService.setUseBiometricForAppPayment(true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('다음 결제부터 $typeName으로 결제됩니다.')),
                  );
                }
              } else {
                showErrorSnackBar(context, '인증이 필요합니다. 카드 등록 페이지에서 다시 설정할 수 있습니다.');
              }
            },
            child: const Text('예'),
          ),
        ],
      ),
    );
  }

  /// 앱결제 선택 시 카카오페이 / 토스 선택 bottom sheet
  Future<AppPaymentMethod?> _showAppPaymentChoice(BuildContext context) async {
    return showModalBottomSheet<AppPaymentMethod>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '결제 수단 선택',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Gap(16),
              ListTile(
                leading: const PhosphorIcon(PhosphorIconsFill.chatCircle, color: Color(0xFFFEE500)),
                title: const Text('카카오페이'),
                onTap: () => Navigator.pop(context, AppPaymentMethod.kakaopay),
              ),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsFill.creditCard, color: AppTheme.accentBlue),
                title: const Text('토스'),
                onTap: () => Navigator.pop(context, AppPaymentMethod.toss),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCallOptionsThenConfirm(BuildContext context) async {
    final options = await Navigator.push<CallOptions>(
      context,
      MaterialPageRoute(
        builder: (_) => const CallOptionsScreen(),
      ),
    );
    if (options != null && mounted) {
      _showCallConfirm(context, options);
    }
  }

  void _showCallConfirm(BuildContext context, CallOptions options) {
    final fareStr = _destination != null ? '${_fmt(_selectedFareAmount)}원' : '';
    final payStr = _selectedPayment == PaymentMethod.cash
        ? '현금'
        : _selectedPayment == PaymentMethod.mileage
            ? '마일'
            : _selectedPayment == PaymentMethod.registeredCard
                ? '등록 카드'
                : '앱결제 (카카오페이/토스)';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('호출 확인'),
        content: Text(
          _destination != null
              ? '$_departureAddr → ${_destination!.name}\n${_distanceKm.toStringAsFixed(1)} km\n$fareStr ($payStr)\n대리운전을 호출하시겠습니까?'
              : '대리운전을 호출하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              if (_isSubmittingCall) return;
              setState(() => _isSubmittingCall = true);
              AppPaymentMethod? chosenApp;
              RegisteredCard? chosenCard;
              if (_selectedPayment == PaymentMethod.appPayment) {
                chosenApp = await _showAppPaymentChoice(context);
                if (chosenApp == null) {
                  if (mounted) setState(() => _isSubmittingCall = false);
                  return;
                }
                final useBiometric = await BiometricPaymentService.useBiometricForAppPayment;
                if (_savedCards.isNotEmpty && _biometricSupported && useBiometric) {
                  final ok = await BiometricPaymentService.authenticate(
                    reason: '저장된 카드로 결제를 진행하려면 인증이 필요합니다',
                  );
                  if (!context.mounted) return;
                  if (!ok) {
                    showErrorSnackBar(context, '인증이 필요합니다. 결제를 진행할 수 없습니다.');
                    if (mounted) setState(() => _isSubmittingCall = false);
                    return;
                  }
                  chosenCard = _savedCards.length == 1
                      ? _savedCards.first
                      : await _showRegisteredCardChoice(context);
                  if (chosenCard == null) {
                    if (mounted) setState(() => _isSubmittingCall = false);
                    return;
                  }
                }
              } else if (_selectedPayment == PaymentMethod.registeredCard) {
                chosenCard = await _showRegisteredCardChoice(context);
                if (chosenCard == null) {
                  if (mounted) setState(() => _isSubmittingCall = false);
                  return;
                }
              }
              Navigator.pop(context);
              try {
                if (_selectedPayment == PaymentMethod.mileage && _destination != null) {
                  final balance = await MileageApi.getBalance();
                  if (balance.balance < _selectedFareAmount) {
                    if (context.mounted) {
                      showErrorSnackBar(
                        context,
                        '마일리지 잔액이 부족합니다. (잔액 ${_fmt(balance.balance)}원)',
                      );
                    }
                    return;
                  }
                }
                final paymentMethod = _selectedPayment == PaymentMethod.cash
                    ? 'cash'
                    : _selectedPayment == PaymentMethod.mileage
                        ? 'mileage'
                        : chosenCard != null
                            ? (chosenApp == AppPaymentMethod.kakaopay ? 'kakaopay' : chosenApp == AppPaymentMethod.toss ? 'tosspay' : 'card')
                            : chosenApp == AppPaymentMethod.kakaopay
                                ? 'kakaopay'
                                : 'tosspay';
                _clientCallIdInFlight ??= generateClientCallId();
                final rideId = await RidesCallApi.createCall(
                  latitude: _departure.latitude,
                  longitude: _departure.longitude,
                  address: _departureAddr,
                  addressDetail: _destination?.address.isNotEmpty == true ? _destination!.address : (_destination?.name ?? ''),
                  phone: '16680001',
                  paymentMethod: paymentMethod,
                  clientCallId: _clientCallIdInFlight,
                  options: options,
                  estimatedDistanceKm: _destination != null ? _distanceKm : null,
                  estimatedFare: _destination != null ? _selectedFareAmount : null,
                  fareType: _destination != null ? _fareTypeString : null,
                  cardId: chosenCard?.id,
                );

                final isCardPayment = chosenCard != null;
                final isPgPayment = _selectedPayment == PaymentMethod.appPayment && chosenApp != null && chosenCard == null;

                if (isCardPayment && context.mounted && rideId != null && rideId.isNotEmpty) {
                  try {
                    await PaymentsApi.chargeWithCard(
                      rideId: rideId,
                      amount: _selectedFareAmount,
                      cardId: chosenCard.id,
                    );
                    if (context.mounted) {
                      showSuccessSnackBar(context, '결제가 완료되었습니다.', title: '결제');
                    }
                  } on DioException catch (e) {
                    if (context.mounted) {
                      final msg = e.response?.data is Map
                          ? (e.response?.data['message'] ?? e.response?.data['error'])?.toString()
                          : null;
                      showErrorSnackBar(
                        context,
                        msg ?? '카드 결제에 실패했습니다. 백엔드 빌링키 연동을 확인해주세요.',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showErrorSnackBar(
                        context,
                        '카드 결제에 실패했습니다. 백엔드 빌링키 연동을 확인해주세요.',
                      );
                    }
                  }
                } else if (isPgPayment && context.mounted && rideId != null && rideId.isNotEmpty) {
                  final screenMethod = chosenApp == AppPaymentMethod.kakaopay
                      ? PaymentScreenMethod.kakaopay
                      : PaymentScreenMethod.toss;
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        rideId: rideId,
                        amount: _selectedFareAmount,
                        orderName: '대리운전 이용료',
                        paymentMethod: screenMethod,
                      ),
                    ),
                  );
                  if (context.mounted && result != null && result['success'] == true) {
                    try {
                      final res = await PaymentsApi.post(
                        amount: _selectedFareAmount,
                        rideId: rideId,
                        pgTid: result['transactionId'] as String?,
                        pgProvider: chosenApp == AppPaymentMethod.kakaopay
                            ? 'kakaopay'
                            : 'tosspay',
                        billingKey: result['billingKey'] as String?,
                        cardName: result['cardName'] as String?,
                        rawResponse: result['rawResponse'] as Map<String, dynamic>?,
                      );
                      if (context.mounted) {
                        final cardSaved = res?['cardSaved'] == true;
                        showSuccessSnackBar(
                          context,
                          cardSaved
                              ? '결제 완료! 카드가 저장되었습니다. 다음 결제부터 사용 가능합니다.'
                              : '결제가 완료되었습니다.',
                          title: '결제',
                        );
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (context.mounted) _maybeShowBiometricEnableDialog(context);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        showErrorSnackBar(context, '결제 정보 전송에 실패했습니다.');
                      }
                    }
                  }
                } else if (context.mounted) {
                  showSuccessSnackBar(context, '접수되었습니다.', title: '호출');
                }

                // 성공/완료되면 다음 호출을 위해 새 키를 쓰도록 초기화
                _clientCallIdInFlight = null;
              } on DioException catch (e) {
                if (context.mounted) {
                  final msg = e.response?.data is Map
                      ? (e.response?.data['error'] ?? e.response?.data['message'])?.toString()
                      : null;
                  final isInsufficient = msg?.toLowerCase().contains('mileage') == true ||
                      msg?.toLowerCase().contains('마일리지') == true;
                  showErrorSnackBar(
                    context,
                    isInsufficient ? '마일리지 잔액이 부족합니다.' : (msg ?? '호출 전송에 실패했습니다.'),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  showErrorSnackBar(context, '호출 전송에 실패했습니다.');
                }
              } finally {
                if (mounted) setState(() => _isSubmittingCall = false);
              }
            },
            child: const Text('호출'),
          ),
        ],
      ),
    );
  }
}

class _MapFocusButtons extends StatelessWidget {
  const _MapFocusButtons({
    required this.focus,
    required this.hasDestination,
    required this.onFocusChanged,
  });

  final _MapFocus focus;
  final bool hasDestination;
  final void Function(_MapFocus) onFocusChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChip(context, '출발지', _MapFocus.departure),
          _buildChip(context, '도착지', _MapFocus.destination),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, _MapFocus f) {
    final selected = focus == f;
    final disabled = f == _MapFocus.destination && !hasDestination;
    return GestureDetector(
      onTap: disabled ? null : () => onFocusChanged(f),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentBlue.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? AppTheme.accentBlue : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPinOverlay extends StatelessWidget {
  const _MapPinOverlay({required this.point, required this.label, required this.color});

  final Offset point;
  final String label;
  final Color color;

  static const double _pinW = 44;
  static const double _pinH = 52;
  /// 라벨·그림자·패딩까지 포함한 가로 반폭 (좁으면 `Stack` 밖으로 나가 잘림)
  static const double _hAlign = 52;

  @override
  Widget build(BuildContext context) {
    final h = MapLocationPin.totalOverlayHeight(hasLabel: label.isNotEmpty, pinHeight: _pinH);
    return Positioned(
      left: point.dx - _hAlign,
      top: point.dy - h,
      child: IgnorePointer(
        child: SizedBox(
          width: _hAlign * 2,
          child: Align(
            alignment: Alignment.topCenter,
            child: MapLocationPin(
              label: label,
              pinColor: color,
              width: _pinW,
              pinHeight: _pinH,
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteLineOverlay extends StatelessWidget {
  const _RouteLineOverlay({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _RouteLinePainter(start: start, end: end),
      ),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  _RouteLinePainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentBlue
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter old) => old.start != start || old.end != end;
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.label,
    required this.text,
    this.onTap,
    this.onRefresh,
  });

  final String label;
  final String text;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('$label : $text', style: const TextStyle(fontSize: 14)),
            ),
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onRefresh,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '내 위치(GPS)로',
              ),
          ],
        ),
      ),
    );
  }
}

class _FareChip extends StatelessWidget {
  const _FareChip({
    required this.icon,
    required this.label,
    required this.fare,
    this.isLoading = false,
    this.color,
    this.isBest = false,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int fare;
  final bool isLoading;
  final Color? color;
  final bool isBest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accentBlue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 100),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                PhosphorIcon(icon, color: c, size: 20),
                if (isBest) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const Gap(4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(isLoading ? '계산 중...' : '${_fmt(fare)}원', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c)),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _PayChip extends StatelessWidget {
  const _PayChip({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentBlue.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.accentBlue : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: 18, color: selected ? AppTheme.accentBlue : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: selected ? AppTheme.accentBlue : Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
