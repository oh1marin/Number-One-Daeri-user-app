import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/rides_call_api.dart';
import '../config/kakao_config.dart';
import '../utils/app_snackbar.dart';
import '../utils/idempotency.dart';
import 'map_location_pin.dart';

const LatLng _kDefaultCenter = LatLng(latitude: 37.5665, longitude: 126.9780);

/// 미니맵: 화면 중앙 = 카메라 중심이므로, 핀 끝이 중앙 좌표에 오도록 위로 절반만큼 이동
const double _kPhoneModalPinH = 58;
const double _kPhoneModalPinLift = (_kPhoneModalPinH + 12 + 10 + 26 + 4) / 2;

/// 전화 접수 시 전화를 걸 번호
const String _kDispatchPhone = '01021848822';

/// 전화번호로 접수 - 위치 확인 모달
void showPhoneCallModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) =>
          _PhoneCallModalContent(scrollController: controller),
    ),
  );
}

// ── 모달 본체 ─────────────────────────────────────────────────────────────────

class _PhoneCallModalContent extends StatefulWidget {
  const _PhoneCallModalContent({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_PhoneCallModalContent> createState() => _PhoneCallModalContentState();
}

class _PhoneCallModalContentState extends State<_PhoneCallModalContent> {
  LatLng? _position;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      if (await Geolocator.checkPermission() == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final cached = await Geolocator.getLastKnownPosition();
      if (mounted && cached != null) {
        setState(() => _position = LatLng(latitude: cached.latitude, longitude: cached.longitude));
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _position = LatLng(latitude: pos.latitude, longitude: pos.longitude));
    } catch (_) {
      if (mounted) setState(() => _position = _kDefaultCenter);
    }
  }

  Future<void> _submitAndCall() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final pos = _position ?? _kDefaultCenter;

    try {
      await RidesCallApi.createCall(
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: '전화호출',
        addressDetail: '',
        phone: _kDispatchPhone,
        paymentMethod: 'cash',
        clientCallId: generateClientCallId(),
      );
    } catch (_) {}


    if (!mounted) return;

    // 2. 모달 닫고 스낵바
    Navigator.pop(context);
    showSuccessSnackBar(context, '호출 접수되었습니다.', title: '호출');

    // 3. 전화 걸기
    final uri = Uri(scheme: 'tel', path: _kDispatchPhone);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('1668-0001', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PhoneCallMap(position: _position, height: 220),
                    const SizedBox(height: 20),
                    Text('현재 위치', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      _position != null ? '전화 호출 (현재 위치)' : '위치 조회 중...',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text('연락처 : 16680001', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 16),
                    Text(
                      '상기 위치로 대리운전 서비스를 이용하시겠습니까?',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitAndCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.orange.shade200,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                '이 위치로 대리운전 호출',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 지도 위젯 (위치를 부모에서 받아 렌더링) ──────────────────────────────────

class _PhoneCallMap extends StatefulWidget {
  const _PhoneCallMap({required this.height, this.position});

  final double height;
  final LatLng? position;

  @override
  State<_PhoneCallMap> createState() => _PhoneCallMapState();
}

class _PhoneCallMapState extends State<_PhoneCallMap> {
  KakaoMapController? _mapController;
  StreamSubscription? _cameraSub;
  bool _isProgrammaticMove = false;
  final bool _kakaoOk = kakaoMapApiKey != 'YOUR_KAKAO_NATIVE_APP_KEY';

  @override
  void didUpdateWidget(_PhoneCallMap old) {
    super.didUpdateWidget(old);
    if (widget.position != null && widget.position != old.position) {
      _moveTo(widget.position!);
    }
  }

  Future<void> _moveTo(LatLng pos) async {
    if (_mapController == null) return;
    _isProgrammaticMove = true;
    await _mapController!.moveCamera(
      cameraUpdate: CameraUpdate(position: pos, zoomLevel: 17),
      animation: const CameraAnimation(duration: 400, autoElevation: true, isConsecutive: false),
    );
    _isProgrammaticMove = false;
  }

  void _onMapCreated(KakaoMapController controller) async {
    _mapController = controller;
    _cameraSub = controller.onCameraMoveEndStream.listen((_) {
      if (!_isProgrammaticMove && widget.position != null) _lockZoom();
    });
    final pos = widget.position;
    if (pos != null) await _moveTo(pos);
  }

  Future<void> _lockZoom() async {
    final pos = widget.position;
    if (_mapController == null || pos == null) return;
    _isProgrammaticMove = true;
    await _mapController!.moveCamera(
      cameraUpdate: CameraUpdate(position: pos, zoomLevel: 17),
      animation: const CameraAnimation(duration: 100, autoElevation: true, isConsecutive: false),
    );
    _isProgrammaticMove = false;
  }

  @override
  void dispose() {
    _cameraSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_kakaoOk) return _buildPlaceholder();

    final center = widget.position ?? _kDefaultCenter;
    // 바깥 `ClipRRect`에 핀까지 넣으면 위로 올린 핀이 잘림. 지도만 둥글게 자름.
    return SizedBox(
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: KakaoMap(
                  initialPosition: center,
                  initialLevel: 17,
                  onMapCreated: _onMapCreated,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(0, -_kPhoneModalPinLift),
                  child: MapLocationPin(
                    label: '출발',
                    pinColor: const Color(0xFFE53935),
                    width: 52,
                    pinHeight: _kPhoneModalPinH,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) {},
              onPointerMove: (_) {},
              onPointerUp: (_) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('위치 지도', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
