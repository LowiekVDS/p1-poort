import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class NetPowerGauge extends StatelessWidget {
  final double value;

  const NetPowerGauge({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final Color pointerColor = value < 0 ? Colors.redAccent : Colors.greenAccent;

    return SizedBox(
      height: 250,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: -5,
            maximum: 5, 
            showLabels: false,
            showTicks: false,
            axisLineStyle: const AxisLineStyle(
              thickness: 0.2,
              cornerStyle: CornerStyle.bothCurve,
              color: Color(0xFF374151), // gray-700
              thicknessUnit: GaugeSizeUnit.factor,
            ),
            pointers: <GaugePointer>[
              RangePointer(
                value: value,
                width: 0.2,
                sizeUnit: GaugeSizeUnit.factor,
                cornerStyle: CornerStyle.bothCurve,
                // Apply the dynamic color
                color: pointerColor,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  "${value.toStringAsFixed(2)} kW",
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                angle: 90,
                positionFactor: 0.1,
              )
            ],
          )
        ],
      ),
    );
  }
}