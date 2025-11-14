import 'dart:async';
import 'package:flutter/material.dart';
import 'package:p1_poort_flutter/config.dart';
import 'package:p1_poort_flutter/services/influxdb_service.dart';
import 'package:p1_poort_flutter/widgets/kpi_card.dart';
import 'package:p1_poort_flutter/widgets/net_power_gauge.dart';
import 'package:p1_poort_flutter/widgets/net_power_line_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InfluxDBService _service = InfluxDBService();
  Timer? _refreshTimer;

  // State variables for all our data
  double _gaugeValue = 0.0;
  List<TimeSeriesData> _lineChartData = [];
  Map<String, dynamic> _kpiData = {};
  bool _isLoading = true;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _fetchAllData(); // Fetch on initial load
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchAllData(); // Auto-refresh
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = "";
      });
    }

    try {
      // Run all fetches in parallel for speed
      final gaugeFuture = _service.fetchCurrentNetPower();
      final kpiFuture = _service.fetchKpiData();
      final lineChartFuture = _service.fetchNetPowerHistory();

      // Wait for all to complete
      final results = await Future.wait([
        gaugeFuture,
        kpiFuture,
        lineChartFuture,
      ]);

      if (mounted) {
        setState(() {
          _gaugeValue = results[0] as double;
          _kpiData = results[1] as Map<String, dynamic>;
          _lineChartData = results[2] as List<TimeSeriesData>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getKpiValue(String field, [int decimals = 3]) {
    final value = _kpiData[field];
    if (value == null) return "--";
    if (value is num) return value.toStringAsFixed(decimals);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digitale meter"),
        actions: [
          // Show a loading spinner in the app bar
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllData, // Enable pull-to-refresh
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display error if any
              if (_error.isNotEmpty)
                Card(
                  color: Colors.red[900],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Error: $_error",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              // --- Extra Info KPIs ---
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: "Tariff",
                      value: _getKpiValue(InfluxConfig.tariffField),
                      icon: Icons.receipt_long,
                      color: Colors.purple.shade300,
                    ),
                  ),
                  Expanded(
                    child: KpiCard(
                      title: "Piek",
                      value:
                          "${_getKpiValue(InfluxConfig.kActiveEnergyImportCurrentAverageDemandField)} kW",
                      icon: Icons.flash_on,
                      color: Colors.orange.shade300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: "Maandpiek",
                      value:
                          "${_getKpiValue(InfluxConfig.kActiveEnergyImportMaximumDemandRunningMonthField)} kW",
                      icon: Icons.flash_on,
                      color: Colors.orange.shade300,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: "13mnd piek",
                      value:
                          "${_getKpiValue(InfluxConfig.kActiveEnergyImportMaximumDemandLast13Months)} kW",
                      icon: Icons.flash_on,
                      color: Colors.orange.shade300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Gauge ---
              const Text(
                "Huidig netto verbruik",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: NetPowerGauge(value: _gaugeValue),
                ),
              ),
              const SizedBox(height: 20),

              // --- Line Chart ---
              const Text(
                "Netto verbruik (recentste 4h)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SizedBox(
                    height: 250,
                    child: NetPowerLineChart(data: _lineChartData),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
