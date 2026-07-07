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
import '../../models/ride_waypoint.dart';
import 'call_options_screen.dart';
import '../../services/biometric_payment_service.dart';
import '../../services/kakao_local_service.dart';
import '../../utils/idempotency.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/payment_guard.dart';
import '../../utils/toss_billing_errors.dart';
import '../../utils/toss_payment_errors.dart';
import '../../utils/user_friendly_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/map_location_pin.dart';
import '../card/card_screen.dart';
import '../payment/toss_payment_screen.dart';
import 'destination_search_screen.dart';
import 'package:gap/gap.dart';

part 'call_map_map_view.dart';
part 'call_map_booking_panel.dart';

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

enum _MapFocus { departure, destination }

/// 24시간 앱 접수 - 대리호출
class CallMapScreen extends StatefulWidget {
  const CallMapScreen({
    super.key,
    this.options,
    this.initialPickup,
    this.initialDropoff,
  });

  final CallOptions? options;
  final String? initialPickup;
  final String? initialDropoff;

  @override
  State<CallMapScreen> createState() => _CallMapScreenState();
}

class _CallMapScreenState extends State<CallMapScreen> {
  KakaoMapController? _mapController;
  LatLng _departure = _kSeoul;
  PlaceSearchResult? _destination;
  final List<RideWaypoint> _waypoints = [];
  String _departureAddr = '위치 조회 중...';
  bool _kakaoOk = false;
  bool _isLoading = true;
  final GlobalKey<_CallBookingPanelState> _bookingKey =
      GlobalKey<_CallBookingPanelState>();

  EstimateResult? _estimate;
  bool _isEstimateLoading = false;
  List<RegisteredCard> _savedCards = [];
  bool _biometricSupported = false;

  int _lockedZoomLevel = 17;
  LatLng _cameraCenter = _kSeoul;
  Offset? _depPinOffset;
  Offset? _destPinOffset;
  StreamSubscription<CameraMoveEndEvent>? _cameraSub;
  bool _isProgrammaticMove = false;
  _MapFocus _mapFocus = _MapFocus.departure;
  bool _focusMoveInProgress = false;
  bool _isDetailEditMode = false;
  _MapFocus? _detailEditTarget;

  bool _isSubmittingCall = false;
  String? _clientCallIdInFlight;

  /// GPS·검색·지도 상세수정으로 사용자가 직접 정한 출발/도착 (자동 GPS 덮어쓰기 방지)
  bool _departureCustomized = false;

  Timer? _estimateDebounce;
  bool _paymentMetaLoaded = false;
  bool _paymentMetaLoading = false;

  @override
  void initState() {
    super.initState();
    _kakaoOk = kakaoMapApiKey != 'YOUR_KAKAO_NATIVE_APP_KEY';
    _loadLocationFast();
    _loadPaymentMetaOnce();
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
        _departureCustomized = false;
        _mapFocus = _MapFocus.departure;
      });
      _cameraCenter = target;
      _lockedZoomLevel = 17;
      _isProgrammaticMove = true;
      await _mapController?.moveCamera(
        cameraUpdate: CameraUpdate(position: target, zoomLevel: 17),
        animation: const CameraAnimation(duration: 0, autoElevation: true, isConsecutive: false),
      );
      _isProgrammaticMove = false;
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 200));
    _focusMoveInProgress = false;
    if (mounted) {
      setState(() {});
      if (_destination != null) _scheduleEstimateFetch();
      await _syncPinOverlays();
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
      if (!_departureCustomized) {
        setState(() {
          _departure = target;
          _departureAddr = addr != null ? '현재위치: $addr' : '현재 위치';
        });
        _cameraCenter = target;
        _lockedZoomLevel = 17;
      }
      if (_destination != null) {
        await _updateMapAndOverlays();
      } else if (!_departureCustomized) {
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
    await _applyRoutePrefill();
  }

  Future<void> _applyRoutePrefill() async {
    final pickup = widget.initialPickup?.trim();
    final dropoff = widget.initialDropoff?.trim();
    if ((pickup == null || pickup.isEmpty) && (dropoff == null || dropoff.isEmpty)) {
      return;
    }

    if (pickup != null && pickup.isNotEmpty) {
      final results = await KakaoLocalService.search(
        pickup,
        lat: _departure.latitude,
        lng: _departure.longitude,
      );
      if (!mounted) return;
      if (results.isNotEmpty) {
        final r = results.first;
        setState(() {
          _departure = LatLng(latitude: r.lat, longitude: r.lng);
          _departureAddr = r.name.isNotEmpty ? r.name : r.address;
          _departureCustomized = true;
        });
        _cameraCenter = _departure;
      } else {
        setState(() => _departureAddr = pickup);
      }
    }

    if (dropoff != null && dropoff.isNotEmpty) {
      final results = await KakaoLocalService.search(
        dropoff,
        lat: _departure.latitude,
        lng: _departure.longitude,
      );
      if (!mounted) return;
      if (results.isNotEmpty) {
        setState(() => _destination = results.first);
        _scheduleEstimateFetch();
        await _updateMapAndOverlays();
      }
    }
  }

  void _openRideTracking(BuildContext context, String rideId) {
    final dropLabel = _destination?.name.isNotEmpty == true
        ? _destination!.name
        : (_destination?.address ?? '');
    Navigator.of(context).pushNamed(
      '/ride-tracking',
      arguments: {
        'rideId': rideId,
        'pickup': _departureAddr,
        'dropoff': dropLabel,
      },
    );
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

  FareType get _selectedFare =>
      _bookingKey.currentState?.selectedFare ?? FareType.normal;

  PaymentMethod get _selectedPayment =>
      _bookingKey.currentState?.selectedPayment ?? PaymentMethod.cash;

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

  Offset _computeDepScreenFor(double mapWidth, double mapHeight) =>
      _depPinOffset ??
      _latLngToScreen(
        _departure.latitude,
        _departure.longitude,
        _cameraCenter.latitude,
        _cameraCenter.longitude,
        _lockedZoomLevel,
        mapWidth,
        mapHeight,
      );

  Offset? _computeDestScreenFor(double mapWidth, double mapHeight) {
    if (_destination == null) return null;
    return _destPinOffset ??
        _latLngToScreen(
          _destination!.lat,
          _destination!.lng,
          _cameraCenter.latitude,
          _cameraCenter.longitude,
          _lockedZoomLevel,
          mapWidth,
          mapHeight,
        );
  }

  Future<void> _syncPinOverlays() async {
    final c = _mapController;
    if (c == null || !mounted) return;
    final dep = await c.toScreenPoint(position: _departure);
    Offset? dest;
    if (_destination != null) {
      dest = await c.toScreenPoint(
        position: LatLng(
          latitude: _destination!.lat,
          longitude: _destination!.lng,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _depPinOffset = dep;
      _destPinOffset = dest;
    });
  }

  void _scheduleEstimateFetch() {
    _estimateDebounce?.cancel();
    _estimateDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _fetchEstimate();
    });
  }

  Future<void> _loadPaymentMetaOnce() async {
    if (_paymentMetaLoaded || _paymentMetaLoading) return;
    _paymentMetaLoading = true;
    try {
      final results = await Future.wait([
        CardsApi.getList(),
        BiometricPaymentService.isSupported,
      ]);
      if (!mounted) return;
      setState(() {
        _savedCards = results[0] as List<RegisteredCard>;
        _biometricSupported = results[1] as bool;
        _paymentMetaLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _paymentMetaLoaded = true;
        });
      }
    } finally {
      _paymentMetaLoading = false;
    }
  }


  LatLng get _focusedPinPosition =>
      _mapFocus == _MapFocus.departure
          ? _departure
          : (_destination != null
              ? LatLng(latitude: _destination!.lat, longitude: _destination!.lng)
              : _departure);

  LatLng get _detailEditPinPosition {
    if (_detailEditTarget == _MapFocus.departure) return _departure;
    if (_destination != null) {
      return LatLng(latitude: _destination!.lat, longitude: _destination!.lng);
    }
    return _departure;
  }

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
    await _syncPinOverlays();
  }

  Future<void> _snapCameraToFocusedPin(KakaoMapController c) async {
    final fp = _focusedPinPosition;
    _cameraCenter = fp;
    _isProgrammaticMove = true;
    await c.moveCamera(
      cameraUpdate: CameraUpdate(position: fp, zoomLevel: _lockedZoomLevel),
      animation: const CameraAnimation(duration: 60, autoElevation: true, isConsecutive: false),
    );
    _isProgrammaticMove = false;
  }

  Future<void> _handleCameraMoveEnd(KakaoMapController c, CameraMoveEndEvent e) async {
    if (_isProgrammaticMove || _focusMoveInProgress) return;

    if (_isDetailEditMode) {
      _cameraCenter = LatLng(latitude: e.latitude, longitude: e.longitude);
      final zoomDrift = e.zoomLevel.round() != _lockedZoomLevel;
      if (zoomDrift) {
        _isProgrammaticMove = true;
        await c.moveCamera(
          cameraUpdate: CameraUpdate(position: _cameraCenter, zoomLevel: _lockedZoomLevel),
          animation: const CameraAnimation(duration: 60, autoElevation: true, isConsecutive: false),
        );
        _isProgrammaticMove = false;
      }
      if (mounted) setState(() {});
      await _syncPinOverlays();
      return;
    }

    final fp = _focusedPinPosition;
    final posDrift = Geolocator.distanceBetween(
          e.latitude,
          e.longitude,
          fp.latitude,
          fp.longitude,
        ) >=
        2;
    final zoomDrift = e.zoomLevel.round() != _lockedZoomLevel;
    if (posDrift || zoomDrift) {
      await _snapCameraToFocusedPin(c);
      if (mounted) setState(() {});
    }
    await _syncPinOverlays();
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
    await _syncPinOverlays();
    _scheduleEstimateFetch();
  }

  Future<void> _fetchEstimate() async {
    if (_destination == null) {
      _estimate = null;
      _isEstimateLoading = false;
      _bookingKey.currentState?.syncEstimate(
        estimate: null,
        isEstimateLoading: false,
      );
      return;
    }
    _isEstimateLoading = true;
    _bookingKey.currentState?.syncEstimate(
      estimate: _estimate,
      isEstimateLoading: true,
    );
    try {
      final result = await RidesEstimateApi.estimate(
        originLatitude: _departure.latitude,
        originLongitude: _departure.longitude,
        destinationLatitude: _destination!.lat,
        destinationLongitude: _destination!.lng,
        waypoints: _waypoints.map((w) => w.toJson()).toList(),
      );
      if (mounted) {
        _estimate = result;
        _isEstimateLoading = false;
        _bookingKey.currentState?.syncEstimate(
          estimate: result,
          isEstimateLoading: false,
        );
      }
    } catch (_) {
      if (mounted) {
        _estimate = null;
        _isEstimateLoading = false;
        _bookingKey.currentState?.syncEstimate(
          estimate: null,
          isEstimateLoading: false,
        );
      }
    }
  }

  void _onMapCreated(KakaoMapController c) async {
    final hadController = _mapController != null;
    await _cameraSub?.cancel();
    _mapController = c;

    _cameraSub = c.onCameraMoveEndStream.listen((e) => _handleCameraMoveEnd(c, e));

    final LatLng initialPosition;
    if (_isDetailEditMode && _detailEditTarget != null) {
      initialPosition = _detailEditPinPosition;
    } else if (hadController) {
      initialPosition = _cameraCenter;
    } else {
      initialPosition = _focusedPinPosition;
    }
    _cameraCenter = initialPosition;
    if (!hadController) {
      _lockedZoomLevel = 17;
    }

    _isProgrammaticMove = true;
    await c.moveCamera(
      cameraUpdate: CameraUpdate(position: initialPosition, zoomLevel: _lockedZoomLevel),
      animation: CameraAnimation(
        duration: hadController ? 0 : 80,
        autoElevation: true,
        isConsecutive: false,
      ),
    );
    _isProgrammaticMove = false;
    if (mounted) setState(() {});
    await _syncPinOverlays();
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
    await _syncPinOverlays();
  }

  @override
  void dispose() {
    _estimateDebounce?.cancel();
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
        _departureAddr = r.name.isNotEmpty ? r.name : r.address;
        _departureCustomized = true;
      });
      await _updateMapAndOverlays();
      if (_destination != null && mounted) {
        _mapFocus = _MapFocus.departure;
        await _centerOnFocusedPin();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _openWaypointSearch() async {
    if (_waypoints.length >= _kMaxWaypoints) {
      if (mounted) {
        showErrorSnackBar(context, '경유지는 최대 $_kMaxWaypoints곳까지 추가할 수 있습니다.');
      }
      return;
    }
    final r = await Navigator.push<PlaceSearchResult>(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationSearchScreen(
          title: '경유지 선택',
          buttonLabel: '경유',
          originLat: _departure.latitude,
          originLng: _departure.longitude,
          onSelect: (_) {},
        ),
      ),
    );
    if (r != null && mounted) {
      setState(() {
        _waypoints.add(RideWaypoint.fromPlace(r, _waypoints.length + 1));
      });
      if (_destination != null) _scheduleEstimateFetch();
    }
  }

  void _removeWaypoint(int index) {
    if (index < 0 || index >= _waypoints.length) return;
    setState(() {
      _waypoints.removeAt(index);
      for (var i = 0; i < _waypoints.length; i++) {
        final w = _waypoints[i];
        _waypoints[i] = RideWaypoint(
          sequence: i + 1,
          name: w.name,
          address: w.address,
          lat: w.lat,
          lng: w.lng,
        );
      }
    });
    if (_destination != null) _scheduleEstimateFetch();
  }

  String get _routeSummaryText {
    if (_destination == null) return _departureAddr;
    return buildRouteSummaryText(
      pickup: _departureAddr,
      waypoints: _waypoints,
      dropoff: _destinationDisplayLabel(_destination!),
    );
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
      body: Column(
        children: [
          Expanded(
            flex: _isDetailEditMode ? 1 : (_destination != null ? 3 : 6),
            child: _CallMapView(
              key: const ValueKey('call_map_view'),
              isLoading: _isLoading,
              kakaoOk: _kakaoOk,
              initialMapPosition: _cameraCenter,
              departure: _departure,
              destination: _destination,
              mapFocus: _mapFocus,
              isDetailEditMode: _isDetailEditMode,
              detailEditTarget: _detailEditTarget,
              allowTouch: _isDetailEditMode,
              onMapCreated: _onMapCreated,
              onMapFocusChanged: _onMapFocusChanged,
              onOpenDetailEdit: _openDetailEdit,
            ),
          ),
          if (!_isDetailEditMode)
            Expanded(
              flex: _destination != null ? 7 : 4,
              child: _CallBookingPanel(
                key: _bookingKey,
                departureAddr: _departureAddr,
                waypoints: List.unmodifiable(_waypoints),
                destination: _destination,
                destinationLabel: _destination != null
                    ? _destinationDisplayLabel(_destination!)
                    : null,
                distanceKm: _distanceKm,
                estimate: _estimate,
                isEstimateLoading: _isEstimateLoading,
                onDepartureTap: _openDepartureSearch,
                onDestinationTap: _openDestinationSearch,
                onAddWaypoint: _openWaypointSearch,
                onRemoveWaypoint: _removeWaypoint,
                onRefreshGps: _refreshToGps,
                onOpenCallFlow: _openCallOptionsThenConfirm,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isDetailEditMode ? _buildDetailEditBottomBar(context) : null,
    );
  }

  Future<void> _openDetailEdit() async {
    _detailEditTarget =
        _destination != null ? _mapFocus : _MapFocus.departure;
    final target = _detailEditPinPosition;
    _cameraCenter = target;
    setState(() => _isDetailEditMode = true);
    final c = _mapController;
    if (c != null) {
      _isProgrammaticMove = true;
      await c.moveCamera(
        cameraUpdate: CameraUpdate(position: target, zoomLevel: _lockedZoomLevel),
        animation: const CameraAnimation(duration: 100, autoElevation: true, isConsecutive: false),
      );
      _isProgrammaticMove = false;
    }
    if (mounted) setState(() {});
    await _syncPinOverlays();
  }

  Future<void> _cancelDetailEdit() async {
    _cameraCenter = _focusedPinPosition;
    setState(() {
      _isDetailEditMode = false;
      _detailEditTarget = null;
    });
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
    await _syncPinOverlays();
  }

  Future<void> _confirmDetailEdit() async {
    final target = _detailEditTarget;
    if (target == null) return;
    final lat = _cameraCenter.latitude;
    final lng = _cameraCenter.longitude;
    final addr = await GeocodeApi.reverse(lat, lng);
    final label = (addr != null && addr.trim().isNotEmpty)
        ? addr.trim()
        : '지도에서 선택한 위치';

    if (!mounted) return;
    setState(() {
      _depPinOffset = null;
      _destPinOffset = null;
      if (target == _MapFocus.departure) {
        _departure = LatLng(latitude: lat, longitude: lng);
        _departureAddr = label;
        _departureCustomized = true;
      } else {
        _destination = PlaceSearchResult(
          name: label,
          address: addr?.trim() ?? label,
          lat: lat,
          lng: lng,
          distance: null,
        );
      }
      _isDetailEditMode = false;
      _detailEditTarget = null;
    });
    if (_destination != null) _scheduleEstimateFetch();
    await _syncPinOverlays();
  }

  String _destinationDisplayLabel(PlaceSearchResult d) {
    if (d.address.trim().isNotEmpty) return d.address.trim();
    return d.name.trim();
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
                  onPressed: _cancelDetailEdit,
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

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  /// 지도 핀 좌표 계산 ( [_CallMapView] 전용 )
  Offset computeDepScreenFor(
    double mapWidth,
    double mapHeight,
  ) =>
      _computeDepScreenFor(mapWidth, mapHeight);

  Offset? computeDestScreenFor(double mapWidth, double mapHeight) =>
      _computeDestScreenFor(mapWidth, mapHeight);

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
                : '앱결제 (카드·카카오·토스)';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('호출 확인'),
        content: Text(
          _destination != null
              ? '$_routeSummaryText\n${_distanceKm.toStringAsFixed(1)} km\n$fareStr ($payStr)\n대리운전을 호출하시겠습니까?'
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
              RegisteredCard? chosenCard;
              if (_selectedPayment == PaymentMethod.appPayment) {
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
                            ? 'card'
                            : 'tosspay';
                _clientCallIdInFlight ??= generateClientCallId();
                final rideId = await RidesCallApi.createCall(
                  latitude: _departure.latitude,
                  longitude: _departure.longitude,
                  address: _departureAddr,
                  addressDetail: _destination?.address.isNotEmpty == true
                      ? _destination!.address
                      : (_destination?.name ?? ''),
                  phone: '01021848822',
                  paymentMethod: paymentMethod,
                  clientCallId: _clientCallIdInFlight,
                  options: options,
                  estimatedDistanceKm: _destination != null ? _distanceKm : null,
                  estimatedFare: _destination != null ? _selectedFareAmount : null,
                  fareType: _destination != null ? _fareTypeString : null,
                  cardId: chosenCard?.id,
                  destinationLatitude: _destination?.lat,
                  destinationLongitude: _destination?.lng,
                  destinationAddress: _destination != null
                      ? (_destination!.address.isNotEmpty
                          ? _destination!.address
                          : _destination!.name)
                      : null,
                  waypoints: _waypoints.isEmpty ? null : List.of(_waypoints),
                );

                final isCardPayment = chosenCard != null;
                final isPgPayment = _selectedPayment == PaymentMethod.appPayment && chosenCard == null;
                var pgPaymentRecorded = !isPgPayment;

                if (isCardPayment && context.mounted && rideId != null && rideId.isNotEmpty) {
                  if (await ensurePaymentAvailable(context)) {
                    try {
                      await PaymentsApi.chargeWithCard(
                        rideId: rideId,
                        amount: _selectedFareAmount,
                        cardId: chosenCard.id,
                        idempotencyKey: PaymentsApi.chargeIdempotencyKeyForRide(rideId),
                      );
                      if (context.mounted) {
                        showSuccessSnackBar(context, '결제가 완료되었습니다.', title: '결제');
                      }
                    } on DioException catch (e) {
                      if (context.mounted) {
                        final msg = tossBillingErrorMessage(e) ??
                            loadErrorMessage(
                              e,
                              fallback: '카드 결제에 실패했습니다. 잠시 후 다시 시도해 주세요.',
                            );
                        if (msg.isNotEmpty) {
                          showErrorSnackBar(context, msg);
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        final msg = tossBillingErrorMessage(e) ??
                            loadErrorMessage(
                              e,
                              fallback: '카드 결제에 실패했습니다. 잠시 후 다시 시도해 주세요.',
                            );
                        if (msg.isNotEmpty) {
                          showErrorSnackBar(context, msg);
                        }
                      }
                    }
                  }
                } else if (isPgPayment && context.mounted && rideId != null && rideId.isNotEmpty) {
                  if (_selectedFareAmount <= 0) {
                    showErrorSnackBar(context, '결제 금액이 없습니다. 도착지를 설정한 뒤 다시 시도해 주세요.');
                  } else if (await ensurePaymentAvailable(context)) {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TossPaymentScreen(
                          rideId: rideId,
                          amount: _selectedFareAmount,
                          orderName: '대리운전 이용료',
                        ),
                      ),
                    );
                    if (!context.mounted) return;

                    if (result != null && result['success'] == true) {
                      pgPaymentRecorded = true;
                      if (context.mounted) {
                        showSuccessSnackBar(
                          context,
                          '결제가 완료되었습니다.',
                          title: '결제',
                        );
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (context.mounted) _maybeShowBiometricEnableDialog(context);
                      }
                    } else if (result?['cancelled'] == true) {
                      showErrorSnackBar(
                        context,
                        '결제가 취소되었습니다. 호출은 접수됐으며, 결제는 운행 후 다시 진행할 수 있습니다.',
                      );
                    } else if (result != null) {
                      final msg = result['message'] as String?;
                      showErrorSnackBar(
                        context,
                        msg != null && msg.isNotEmpty
                            ? msg
                            : tossPaymentErrorMessage(
                                Exception('결제 실패'),
                              ),
                      );
                    }
                  }
                } else if (context.mounted) {
                  showSuccessSnackBar(context, '접수되었습니다.', title: '호출');
                }

                if (context.mounted && rideId != null && rideId.isNotEmpty) {
                  _openRideTracking(context, rideId);
                  if (isPgPayment && !pgPaymentRecorded) {
                    showErrorSnackBar(
                      context,
                      '결제가 완료되지 않았습니다. 운행 종료 후 결제를 진행해 주세요.',
                    );
                  }
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
  const _RouteLineOverlay({
    required this.start,
    required this.end,
    required this.width,
    required this.height,
  });

  final Offset start;
  final Offset end;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(width, height),
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
    this.compact = false,
    this.onTap,
    this.onRefresh,
    this.onDelete,
  });

  final String label;
  final String text;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: compact ? 7 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label : $text',
                key: ValueKey('$label-$text'),
                style: TextStyle(fontSize: compact ? 13 : 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onRefresh,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '내 위치(GPS)로',
              ),
            if (onDelete != null) ...[
              const Gap(4),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('삭제', style: TextStyle(fontSize: 12)),
              ),
            ],
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
