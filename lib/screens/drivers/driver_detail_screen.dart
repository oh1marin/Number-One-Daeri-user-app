import 'package:flutter/material.dart';

import '../../api/drivers_api.dart';
import '../../models/driver.dart';

class DriverDetailScreen extends StatefulWidget {
  const DriverDetailScreen({super.key, required this.driverId});

  final String driverId;

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  Driver? _driver;
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
      final d = await DriversApi.get(widget.driverId);
      setState(() {
        _driver = d;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기사 상세'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _driver == null
                  ? const Center(child: Text('기사를 찾을 수 없습니다.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_driver!.name,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                              '연락처: ${_driver!.phone ?? _driver!.mobile ?? '-'}'),
                        ],
                      ),
                    ),
    );
  }
}
