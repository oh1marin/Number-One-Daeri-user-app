part of 'call_map_screen.dart';

/// 지도 + 핀 오버레이만 담당. 요금/결제 칩 변경 시 이 위젯은 부모 [setState] 없이 유지된다.
class _CallMapView extends StatelessWidget {
  const _CallMapView({
    super.key,
    required this.isLoading,
    required this.kakaoOk,
    required this.initialMapPosition,
    required this.departure,
    required this.destination,
    required this.mapFocus,
    required this.isDetailEditMode,
    required this.detailEditTarget,
    required this.onMapCreated,
    required this.onMapFocusChanged,
    required this.onOpenDetailEdit,
    this.allowTouch = false,
  });

  final bool isLoading;
  final bool kakaoOk;
  final LatLng initialMapPosition;
  final LatLng departure;
  final PlaceSearchResult? destination;
  final _MapFocus mapFocus;
  final bool isDetailEditMode;
  final _MapFocus? detailEditTarget;
  final bool allowTouch;
  final void Function(KakaoMapController) onMapCreated;
  final Future<void> Function(_MapFocus) onMapFocusChanged;
  final Future<void> Function() onOpenDetailEdit;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentBlue),
      );
    }
    if (!kakaoOk) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Text('지도를 불러올 수 없습니다.')),
      );
    }

    final screenState = context.findAncestorStateOfType<_CallMapScreenState>();
    if (screenState == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mapWidth =
              constraints.maxWidth > 0 ? constraints.maxWidth : 400.0;
          final mapHeight =
              constraints.maxHeight > 0 ? constraints.maxHeight : 400.0;
          final depScreen =
              screenState.computeDepScreenFor(mapWidth, mapHeight);
          final destScreen =
              screenState.computeDestScreenFor(mapWidth, mapHeight);
          final center = Offset(mapWidth / 2, mapHeight / 2);
          final focusForPin =
              (allowTouch && isDetailEditMode && detailEditTarget != null)
                  ? detailEditTarget!
                  : mapFocus;
          final showFocusedAtCenter = !allowTouch || isDetailEditMode;
          final startPin = showFocusedAtCenter &&
                  focusForPin == _MapFocus.departure
              ? center
              : depScreen;
          final endPin = destScreen != null
              ? (showFocusedAtCenter && focusForPin == _MapFocus.destination
                  ? center
                  : destScreen)
              : null;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              KakaoMap(
                key: const ValueKey('call_kakao_map'),
                initialPosition: initialMapPosition,
                initialLevel: 17,
                onMapCreated: onMapCreated,
              ),
              if (showFocusedAtCenter) ...[
                _MapPinOverlay(
                  point: center,
                  label: focusForPin == _MapFocus.departure ? '출발' : '도착',
                  color: focusForPin == _MapFocus.departure
                      ? _kPinDepartureRed
                      : _kPinDestinationRed,
                ),
                if (focusForPin == _MapFocus.departure && destScreen != null)
                  _MapPinOverlay(
                    point: destScreen,
                    label: '도착',
                    color: _kPinDestinationRed,
                  ),
                if (focusForPin == _MapFocus.destination)
                  _MapPinOverlay(
                    point: depScreen,
                    label: '출발',
                    color: _kPinDepartureRed,
                  ),
              ] else ...[
                _MapPinOverlay(
                  point: depScreen,
                  label: '출발',
                  color: _kPinDepartureRed,
                ),
                if (destScreen != null)
                  _MapPinOverlay(
                    point: destScreen,
                    label: '도착',
                    color: _kPinDestinationRed,
                  ),
              ],
              if (endPin != null && !allowTouch)
                _RouteLineOverlay(
                  start: startPin,
                  end: endPin,
                  width: mapWidth,
                  height: mapHeight,
                ),
              if (!allowTouch) ...[
                Positioned(
                  right: 12,
                  top: 12,
                  child: _MapFocusButtons(
                    focus: mapFocus,
                    hasDestination: destination != null,
                    onFocusChanged: onMapFocusChanged,
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
                      onTap: () => onOpenDetailEdit(),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_location_alt,
                              size: 18,
                              color: AppTheme.accentBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              destination != null
                                  ? '위치 상세수정 (${mapFocus == _MapFocus.departure ? '출발' : '도착'})'
                                  : '위치 상세수정',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.accentBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
    );
  }
}
