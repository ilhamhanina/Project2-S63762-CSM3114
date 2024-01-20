import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'schedule_truck.dart';

class AddTruckScreen extends StatelessWidget {
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController driverContactController = TextEditingController();
  String selectedTruckType = 'Full Load';
  String selectedTruckUsage = 'Food Distribution';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Image.asset(
                "images/logo.png",
                width: 30,
                height: 30,
              ),
              const SizedBox(width: 8),
              Text("Register Truck"),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Register Truck",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField("Truck Plate Number", plateNumberController),
              const SizedBox(height: 16),
              _buildTextField("Driver Name", driverNameController),
              const SizedBox(height: 16),
              _buildNumericTextField(
                  "Driver's Contact Number", driverContactController),
              const SizedBox(height: 16),
              _buildDropDown(
                "Truck Type",
                selectedTruckType,
                _truckTypeOptions,
                (newValue) {
                  selectedTruckType = newValue;
                },
              ),
              const SizedBox(height: 16),
              _buildDropDown(
                "Truck Usage",
                selectedTruckUsage,
                _truckUsageOptions,
                (newValue) {
                  selectedTruckUsage = newValue;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _registerTruck(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple,
                ),
                child: const Text(
                  "Register",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // To build a text input field
  Widget _buildTextField(String labelText, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // To build a numeric text input field
  Widget _buildNumericTextField(
      String labelText, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // To build a dropdown input field
  Widget _buildDropDown(String labelText, String value, List<String> options,
      Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: (newValue) {
        // Update the corresponding variable
        onChanged(newValue!);
      },
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // To handle truck registration
  void _registerTruck(BuildContext context) async {
    // Check if any of the fields is empty
    if (plateNumberController.text.isEmpty ||
        driverNameController.text.isEmpty ||
        driverContactController.text.isEmpty) {
      // Show an error message if any field is empty
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill in all the details.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Can't proceed to next screen if all details not filled.
    }

    final url = Uri.https(
      'hauliertrackingapp-default-rtdb.asia-southeast1.firebasedatabase.app',
      'truck.json',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'plateNumber': plateNumberController.text,
          'driverName': driverNameController.text,
          'driverContact': driverContactController.text,
          'truckType': selectedTruckType,
          'truckUsage': selectedTruckUsage,
        }),
      );

      if (response.statusCode == 200) {
        // Show AlertDialog after successful registration
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Truck added successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleCard(
                          truck: {
                            'plateNumber': plateNumberController.text,
                            'driverName': driverNameController.text,
                            'truckType': selectedTruckType,
                          },
                          onTrucksScheduled:
                              (List<Map<String, dynamic>> scheduledTrucks) {},
                        ),
                      ),
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        print('Truck registration failed: ${response.statusCode}');
        //Show error message
      }
    } catch (error) {
      print('Error during truck registration: $error');
      // Show network errors or other exceptions
    }
  }

  // Dropdown options
  List<String> _truckTypeOptions = [
    'Full Load',
    'Part Load',
    'Groupage',
    'Temperature Contolled Loads',
    'Border Trucking',
    'Project Cargo',
    'In Transit Fumigation',
  ];

  List<String> _truckUsageOptions = [
    'Food Distribution',
    'Construction Materials Transport',
    'Waste Management',
    'Moving and Relocation Services',
    'Parcel and Package Delivery',
    'Tanker Trucks for Liquid Cargo',
    'Livestock Transportation',
    'Military and Defense',
  ];
}
