import 'package:influxdb_client/api.dart';
import 'package:p1_poort_flutter/config.dart';

// A simple model for our line chart data points
class TimeSeriesData {
  final DateTime time;
  final double value;
  TimeSeriesData(this.time, this.value);
}

class InfluxDBService {
  late InfluxDBClient _client;
  late QueryService _queryService;

  InfluxDBService() {
    _client = InfluxDBClient(
      url: InfluxConfig.kInlfuxDbUrl,
      token: InfluxConfig.kInfluxDbToken,
      org: InfluxConfig.kInfluxDbOrg,
      bucket: InfluxConfig.kInfluxDbBucket,
    );
    _queryService = _client.getQueryService();
  }

  /// Helper to run a query and handle basic parsing
  Future<List<FluxRecord>> _runQuery(String query) async {
    final stream = await _queryService.query(query);
    return stream.toList();
  }

  /// Fetches the current Net Power (A - B) for the gauge
  Future<double> fetchCurrentNetPower() async {
    final fluxQuery = '''
      queryA = from(bucket: "${InfluxConfig.kInfluxDbBucket}")
        |> range(start: -30m)
        |> filter(fn: (r) => r["_measurement"] == "${InfluxConfig.kMeasurement}" and r["_field"] == "${InfluxConfig.kCurrentInjectionField}")
        |> last()
      queryB = from(bucket: "${InfluxConfig.kInfluxDbBucket}")
        |> range(start: -30m)
        |> filter(fn: (r) => r["_measurement"] == "${InfluxConfig.kMeasurement}" and r["_field"] == "${InfluxConfig.kCurrentUsageField}")
        |> last()
      union(tables: [queryA, queryB])
    ''';

    final records = await _runQuery(fluxQuery);
    double? valA;
    double? valB;

    for (var record in records) {
      if (record["_field"] == InfluxConfig.kCurrentInjectionField) {
        valA = (record["_value"] as num).toDouble();
      }
      if (record["_field"] == InfluxConfig.kCurrentUsageField) {
        valB = (record["_value"] as num).toDouble();
      }
    }

    if (valA != null && valB != null) {
      return valA - valB;
    } else {
      throw Exception("Incomplete data for Net Power");
    }
  }

  /// Fetches the "Extra Info" KPIs for the home screen
  Future<Map<String, dynamic>> fetchKpiData() async {
    final fluxQuery = '''
      from(bucket: "${InfluxConfig.kInfluxDbBucket}")
        |> range(start: -5m)
        |> filter(fn: (r) => r["_measurement"] == "${InfluxConfig.kMeasurement}" and (
             r["_field"] == "${InfluxConfig.tariffField}" or 
             r["_field"] == "${InfluxConfig.kActiveEnergyImportCurrentAverageDemandField}" or 
             r["_field"] == "${InfluxConfig.kActiveEnergyImportMaximumDemandRunningMonthField}" or
             r["_field"] == "${InfluxConfig.kActiveEnergyImportMaximumDemandLast13Months}"
           ))
        |> last()
        |> group(columns: ["_field"]) // Group by field to get one row per field
    ''';

    final records = await _runQuery(fluxQuery);
    final Map<String, dynamic> kpiData = {};

    for (var record in records) {
      kpiData[record["_field"]] = record["_value"];
    }
    return kpiData;
  }

  /// Fetches the last 3 hours of Net Power (A - B), aggregated per minute
  Future<List<TimeSeriesData>> fetchNetPowerHistory() async {
    final fluxQuery = '''
      dataA = from(bucket: "${InfluxConfig.kInfluxDbBucket}")
        |> range(start: -4h)
        |> filter(fn: (r) => r["_measurement"] == "${InfluxConfig.kMeasurement}" and r["_field"] == "${InfluxConfig.kCurrentInjectionField}")
        |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)

      dataB = from(bucket: "${InfluxConfig.kInfluxDbBucket}")
        |> range(start: -4h)
        |> filter(fn: (r) => r["_measurement"] == "${InfluxConfig.kMeasurement}" and r["_field"] == "${InfluxConfig.kCurrentUsageField}")
        |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)

      // Join the two streams (A and B) on time, then calculate A-B
      join(tables: {a: dataA, b: dataB}, on: ["_time"])
        |> map(fn: (r) => ({ _time: r._time, _value: r._value_a - r._value_b }))
        |> sort(columns: ["_time"])
    ''';

    final records = await _runQuery(fluxQuery);
    return records.map((r) {
      return TimeSeriesData(
        DateTime.parse(r["_time"]),
        (r["_value"] as num).toDouble(),
      );
    }).toList();
  }

  /// Fetches aggregated energy usage for the bar chart
  Future<List<TimeSeriesData>> fetchEnergyUsage({
    required String rangeStart,
    required String windowPeriod,
  }) async {
    final fluxQuery = '''
      from(bucket: "${InfluxConfig.kInfluxDbBucket}")
        |> range(start: $rangeStart)
        |> filter(fn: (r) => r["_measurement"] == "${InfluxConfig.kMeasurement}" and r["_field"] == "${InfluxConfig.energyField}")
        |> aggregateWindow(every: $windowPeriod, fn: sum, createEmpty: false) // Sum up consumption
        |> sort(columns: ["_time"])
    ''';

    final records = await _runQuery(fluxQuery);
    return records.map((r) {
      return TimeSeriesData(
        DateTime.parse(r["_time"]),
        (r["_value"] as num).toDouble(),
      );
    }).toList();
  }

  void dispose() {
    _client.close();
  }
}