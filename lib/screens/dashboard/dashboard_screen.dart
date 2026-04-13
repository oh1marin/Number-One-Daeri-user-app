import 'package:flutter/material.dart';

import '../../api/dashboard_api.dart';
import '../../services/auth_service.dart';
import '../../routes/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DashboardApi.getDashboard();
      if (res.success && res.data != null) {
        setState(() {
          _data = res.data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.error ?? '로드 실패';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '오늘 현황',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(_data != null
                                  ? '데이터: $_data'
                                  : '데이터 없음'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _navChip(context, '고객', Icons.people, AppRouter.customerList),
                          _navChip(context, '기사', Icons.directions_car, AppRouter.driverList),
                          _navChip(context, '운행', Icons.route, AppRouter.rideList),
                          _navChip(context, '근태', Icons.calendar_month, AppRouter.attendance),
                          _navChip(context, '세금계산서', Icons.receipt, AppRouter.invoiceList),
                          _navChip(context, '요금설정', Icons.settings, AppRouter.fareSettings),
                          _navChip(context, '1:1 문의', Icons.chat, AppRouter.inquiryList),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _navChip(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }
}
