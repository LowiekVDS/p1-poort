import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:p1_poort_flutter/services/influxdb_service.dart';
import 'package:intl/intl.dart';

class NetPowerLineChart extends StatelessWidget {
  final List<TimeSeriesData> data;

  const NetPowerLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No data for this period."));
    }

    // Find min/max values for dynamic Y-axis scaling
    final double minY = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final double maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final double buffer = (maxY - minY).abs() * 0.1; // 10% buffer

    // Define gradient colors for import (red) and export (green)
    final List<Color> gradientColors = [
      Colors.greenAccent, // Above zero
      Colors.greenAccent,
      Colors.redAccent,   // Below zero
      Colors.redAccent,
    ];

    // Calculate where the gradient should stop (at the zero line)
    // This makes everything above 0 green and below 0 red.
    final double zeroPercent = (maxY / (maxY - minY)).clamp(0, 1);
    final List<double> stops = [0.0, zeroPercent, zeroPercent, 1.0];

    return LineChart(
      LineChartData(
        minY: (minY - buffer).floorToDouble(), // Set Y-axis min
        maxY: (maxY + buffer).ceilToDouble(),  // Set Y-axis max
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFF374151), // gray-700
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 3600 * 1000, // Show a label every hour
              // getTitlesWidget: (value, meta) {
              //   final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              //   return SideTitleWidget(
              //     // axisSide: meta.axisSide, // <-- This was the error
              //     child: Text(
              //       DateFormat.Hm().format(dt), // "HH:mm"
              //       style: const TextStyle(color: Colors.grey, fontSize: 10),
              //     ),
              //   );
              // },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              // getTitlesWidget: (value, meta) {
              //   // --- FIX START ---
              //   // The Text widget must be wrapped in a SideTitleWidget.
              //   return SideTitleWidget(
              //     // axisSide: meta.axisSide, // <-- This was the error
              //     space: 0, // Add 0 space
              //     child: Text(
              //       "${value.toInt()}kW",
              //       style: const TextStyle(color: Colors.grey, fontSize: 10),
              //     ),
              //   );
              //   // --- FIX END ---
              // },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFF374151)), // gray-700
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.map((d) {
              return FlSpot(
                  d.time.millisecondsSinceEpoch.toDouble(), d.value);
            }).toList(),
            isCurved: true, // Make it smooth!
            curveSmoothness: 0.35,
            // color: Colors.blueAccent, // <-- Removed this
            
            // --- ADDED ---
            // Apply the green/red gradient directly to the line
            gradient: LinearGradient(
              colors: gradientColors,
              stops: stops,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            // --- END ADDED ---

            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),

            // --- CHANGED ---
            // Hide the area fill below the bar
            belowBarData: BarAreaData(
              show: false,
            ),
            // --- END CHANGED ---
          ),
        ],
      ),
    );
  }
}