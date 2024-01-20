import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class TruckUtilization extends StatefulWidget {
  @override
  _TruckUsageScreenState createState() => _TruckUsageScreenState();
}

class _TruckUsageScreenState extends State<TruckUtilization> {
  Map<String, double> truckUsagePercentages = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Fetch truck data from Firebase and calculate usage percentages
  Future<void> fetchData() async {
    final url = Uri.https(
      'hauliertrackingapp-default-rtdb.asia-southeast1.firebasedatabase.app',
      'truck.json',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      // Calculate the percentage based on your data
      double totalTrucks = data.length.toDouble();

      Map<String, int> truckUsageCount =
          {}; // Map to store count for each usage category

      data.values.forEach((truck) {
        String truckUsage = truck['truckUsage'] ?? 'Other';
        truckUsageCount[truckUsage] = (truckUsageCount[truckUsage] ?? 0) + 1;
      });

      truckUsagePercentages = Map<String, double>.fromEntries(
        truckUsageCount.entries.map((entry) {
          return MapEntry(entry.key, entry.value / totalTrucks);
        }),
      );

      setState(() {
        // Update the UI with the calculated percentages
      });
    } else {
      print('Failed to fetch truck data from Firebase');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              "images/logo.png",
              width: 30,
            ),
            const SizedBox(width: 8),
            Text("Truck Utilization"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Display usage percentages using LinearPercentIndicator
            for (var entry in truckUsagePercentages.entries)
              Column(
                children: [
                  LinearPercentIndicator(
                    animation: true,
                    animationDuration: 1000,
                    lineHeight: 40,
                    percent: entry.value,
                    progressColor: Colors.deepPurple,
                    backgroundColor: Colors.deepPurple.shade200,
                    center: Text(
                      '${(entry.value * 100).toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  Text(
                      '${(entry.value * 100).toStringAsFixed(2)}% for ${entry.key}'),
                  SizedBox(height: 20),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
