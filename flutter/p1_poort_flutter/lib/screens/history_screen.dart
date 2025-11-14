import 'package:flutter/material.dart';
import 'package:p1_poort_flutter/services/influxdb_service.dart';
import 'package:p1_poort_flutter/widgets/energy_usage_bar_chart.dart';

// Enum to define the time ranges
enum EnergyRange { hour, day, week }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final InfluxDBService _service = InfluxDBService();
  EnergyRange _selectedRange = EnergyRange.hour; // Default selection

  // State
  List<TimeSeriesData> _chartData = [];
  bool _isLoading = true;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _fetchChartData(); // Fetch data for the default range
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchChartData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = "";
      });
    }

    String rangeStart;
    String windowPeriod;

    // Determine query parameters based on selection
    switch (_selectedRange) {
      case EnergyRange.hour:
        rangeStart = "-1d"; // Last 24 hours
        windowPeriod = "1h"; // Grouped by 1 hour
        break;
      case EnergyRange.day:
        rangeStart = "-7d"; // Last 7 days
        windowPeriod = "1d"; // Grouped by 1 day
        break;
      case EnergyRange.week:
        rangeStart = "-12w"; // Last 12 weeks
        windowPeriod = "1w"; // Grouped by 1 week
        break;
    }

    try {
      final data = await _service.fetchEnergyUsage(
        rangeStart: rangeStart,
        windowPeriod: windowPeriod,
      );
      if (mounted) {
        setState(() {
          _chartData = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Energy History"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- The Selector Buttons ---
            SegmentedButton<EnergyRange>(
              segments: const <ButtonSegment<EnergyRange>>[
                ButtonSegment<EnergyRange>(
                  value: EnergyRange.hour,
                  label: Text('Per Hour'),
                  icon: Icon(Icons.hourglass_empty),
                ),
                ButtonSegment<EnergyRange>(
                  value: EnergyRange.day,
                  label: Text('Per Day'),
                  icon: Icon(Icons.view_day),
                ),
                ButtonSegment<EnergyRange>(
                  value: EnergyRange.week,
                  label: Text('Per Week'),
                  icon: Icon(Icons.view_week),
                ),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (Set<EnergyRange> newSelection) {
                setState(() {
                  _selectedRange = newSelection.first;
                  _fetchChartData(); // Re-fetch data when selection changes
                });
              },
            ),
            const SizedBox(height: 20),

            // --- The Chart Area ---
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error.isNotEmpty
                          ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)))
                          : EnergyUsageBarChart(
                              data: _chartData,
                              range: _selectedRange,
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}