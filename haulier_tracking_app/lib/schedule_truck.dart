import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ScheduleCard extends StatefulWidget {
  final Function(List<Map<String, dynamic>> scheduledTrucks) onTrucksScheduled;

  const ScheduleCard({
    Key? key,
    required this.onTrucksScheduled,
    required Map truck,
  }) : super(key: key);

  @override
  _ScheduleCardState createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  DateTime? selectedDepartureDate;
  String? selectedInboundPlace;
  String? selectedOutboundPlace;
  List<Map<String, dynamic>> trucks = [];
  List<Map<String, dynamic>> _scheduledTrucks = [];

  List<String> places = [
    'Pahang',
    'Perak',
    'Terengganu',
    'Perlis',
    'Selangor',
    'Negeri Sembilan',
    'Johor',
    'Kelantan',
    'Kedah',
    'Pulau Pinang',
    'Melaka',
    'Sabah',
    'Sarawak'
  ];

  @override
  void initState() {
    super.initState();
    fetchTruckDataFromFirebase();
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
            Text("Truck Schedule"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          margin: EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var truck in trucks)
                  Column(
                    children: [
                      ListTile(
                        title: Text("Plate Number: ${truck['plateNumber']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Assigned Driver: ${truck['driverName']}"),
                            Text("Truck Type: ${truck['truckType']}"),
                          ],
                        ),
                        onTap: () async {
                          await _showScheduleDialog(truck);
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fetch truck data from Firebase
  Future<void> fetchTruckDataFromFirebase() async {
    final url = Uri.https(
      'hauliertrackingapp-default-rtdb.asia-southeast1.firebasedatabase.app',
      'truck.json',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      List<Map<String, dynamic>> fetchedTrucks = [];
      data.forEach((key, value) {
        Map<String, dynamic> truck = value;
        truck['id'] = key;
        fetchedTrucks.add(truck);
      });

      setState(() {
        trucks = fetchedTrucks;
      });
    } else {
      throw Exception('Failed to fetch truck data from Firebase');
    }
  }

  // Select the estimated departure date
  Future<DateTime?> _selectDepartureDate(
      BuildContext context, Map<String, dynamic> truck) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDepartureDate = pickedDate;
        truck['selectedDepartureDate'] = pickedDate;
      });
    }

    return pickedDate;
  }

  // Show the schedule dialog
  Future<void> _showScheduleDialog(Map<String, dynamic> truck) async {
    DateTime? dialogSelectedDepartureDate = truck['selectedDepartureDate'];

    String? selectedInboundPlace = truck['selectedInboundPlace'];
    String? selectedOutboundPlace = truck['selectedOutboundPlace'];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Schedule for ${truck['plateNumber']}"),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select Estimated Date of Departure:"),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate =
                          await _selectDepartureDate(context, truck);
                      if (pickedDate != null) {
                        setState(() {
                          dialogSelectedDepartureDate = pickedDate;
                          truck['selectedDepartureDate'] = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      dialogSelectedDepartureDate == null
                          ? 'Pick Departure Date'
                          : DateFormat('dd-MM-yyyy')
                              .format(dialogSelectedDepartureDate!),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("Select Inbound:"),
                  DropdownButton<String>(
                    value: selectedInboundPlace,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedInboundPlace = newValue;
                        truck['selectedInboundPlace'] = newValue;
                      });
                    },
                    items: places.map<DropdownMenuItem<String>>(
                      (String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      },
                    ).toList(),
                  ),
                  SizedBox(height: 16),
                  Text("Select Outbound:"),
                  DropdownButton<String>(
                    value: selectedOutboundPlace,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedOutboundPlace = newValue;
                        truck['selectedOutboundPlace'] = newValue;
                      });
                    },
                    items: places.map<DropdownMenuItem<String>>(
                      (String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Check if all required fields are filled
                    if (dialogSelectedDepartureDate != null &&
                        selectedInboundPlace != null &&
                        selectedOutboundPlace != null) {
                      await saveScheduledTruckToFirebase({
                        'plateNumber': truck['plateNumber'],
                        'estimatedDepartureDate': dialogSelectedDepartureDate,
                        'inboundPlace': selectedInboundPlace,
                        'outboundPlace': selectedOutboundPlace,
                      });

                      // Add the saved truck to the list
                      _scheduledTrucks.add({
                        'plateNumber': truck['plateNumber'],
                        'estimatedDepartureDate': dialogSelectedDepartureDate,
                        'inboundPlace': selectedInboundPlace,
                        'outboundPlace': selectedOutboundPlace,
                      });

                      widget.onTrucksScheduled(_scheduledTrucks);
                      Navigator.pop(context, _scheduledTrucks);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill in all the details.'),
                        ),
                      );
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Save scheduled truck to Firebase
  Future<void> saveScheduledTruckToFirebase(Map<String, dynamic> truck) async {
    final url = Uri.https(
      'hauliertrackingapp-default-rtdb.asia-southeast1.firebasedatabase.app',
      'assignedTrucks.json',
    );

    // Convert DateTime to string (date only)
    String formattedDepartureDate = truck['estimatedDepartureDate']
            ?.toLocal()
            .toIso8601String()
            .split('T')[0] ??
        '';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'plateNumber': truck['plateNumber'],
          'estimatedDepartureDate': formattedDepartureDate,
          'inboundPlace': truck['inboundPlace'],
          'outboundPlace': truck['outboundPlace'],
        }),
      );

      print(
          "Save Scheduled Truck - Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        print('Scheduled truck saved successfully');
      } else {
        print(
            'Failed to save scheduled truck. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Error during saveScheduledTruckToFirebase: $error');
    }
  }
}
