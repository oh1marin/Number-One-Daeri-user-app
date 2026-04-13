import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../api/geocode_api.dart';
import '../../services/kakao_local_service.dart';
import '../../theme/app_theme.dart';

/// 도착지 선택 - 주소/장소 검색 화면
class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({
    super.key,
    this.originLat,
    this.originLng,
    this.title = '도착지 선택',
    this.buttonLabel = '도착',
    required this.onSelect,
  });

  final double? originLat;
  final double? originLng;
  final String title;
  final String buttonLabel;
  final void Function(PlaceSearchResult result) onSelect;

  @override
  State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<PlaceSearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _searched = true;
    });
    final list = await GeocodeApi.search(
      q,
      originLat: widget.originLat,
      originLng: widget.originLng,
    );
    if (mounted) {
      setState(() {
        _results = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              onSubmitted: _search,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                hintText: '터치하여 주소검색',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                prefixIcon: Icon(Icons.place, color: Colors.red.shade400, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white70),
                  onPressed: () {},
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _searched && _results.isEmpty
                      ? Center(
                          child: Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : _searched
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _results.length,
                              itemBuilder: (_, i) {
                                final r = _results[i];
                                return _ResultTile(
                                  result: r,
                                  originLat: widget.originLat,
                                  originLng: widget.originLng,
                                  buttonLabel: widget.buttonLabel,
                                  onTap: () {
                                    widget.onSelect(r);
                                    Navigator.pop(context, r);
                                  },
                                );
                              },
                            )
                          : _buildRecentSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('최근 검색내역', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text('편집', style: TextStyle(color: AppTheme.accentBlue)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '최근 검색내역이 없습니다.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.onTap,
    this.originLat,
    this.originLng,
    this.buttonLabel = '도착',
  });

  final PlaceSearchResult result;
  final VoidCallback onTap;
  final String buttonLabel;
  final double? originLat;
  final double? originLng;

  @override
  Widget build(BuildContext context) {
    double? dist;
    if (originLat != null && originLng != null && result.distance != null) {
      dist = result.distance! / 1000;
    } else if (originLat != null && originLng != null) {
      dist = _haversine(originLat!, originLng!, result.lat, result.lng);
    }
    final distStr = dist != null ? ' (${dist.toStringAsFixed(1)} km)' : '';
    return ListTile(
      title: Text(result.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        result.address + distStr,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 70,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.accentBlue,
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Text(buttonLabel),
        ),
      ),
      onTap: onTap,
    );
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = math.pi / 180;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // km
  }
}
