import 'package:flutter/material.dart';
import 'package:haulier_tracking_app/truck_utilization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'schedule_truck.dart';
import 'add_truck.dart';
import 'signin_screen.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> assignedTrucks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAssignedTrucksFromFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading data'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No assigned trucks available'),
            );
          } else {
            assignedTrucks = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Welcome to Haulier Tracking App!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Truck Scheduling',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: assignedTrucks.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> truck = assignedTrucks[index];
                      return ListTile(
                        title: Text('Plate Number: ${truck['plateNumber']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Departure Date: ${truck['selectedDepartureDate']}'),
                            Text('Inbound: ${truck['selectedInboundPlace']}'),
                            Text('Outbound: ${truck['selectedOutboundPlace']}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            confirmDelivery(context, truck);
                          },
                          child: Text('Delivered'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      drawer: buildDrawer(context),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Image.asset(
        "images/logo.png",
        width: 140,
      ),
      titleSpacing: 10,
      elevation: 14,
    );
  }

  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const SizedBox(
            height: 60.0,
            child: const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple,
              ),
              child: Text('Menu'),
            ),
          ),
          ListTile(
            title: const Text('Register Truck'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTruckScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Schedule Truck'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleCard(
                    truck: {},
                    onTrucksScheduled:
                        (List<Map<String, dynamic>> scheduledTrucks) {
                      onTrucksScheduled(scheduledTrucks);
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Truck Utilization'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TruckUtilization(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () {
              // logout actions and navigate to SignInScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
                (Route<dynamic> route) => false, // Prevent going back
              );
            },
          ),
        ],
      ),
    );
  }

  // Fetch assigned trucks from Firebase
  Future<List<Map<String, dynamic>>> fetchAssignedTrucksFromFirebase() async {
    final url = Uri.https(
      'hauliertrackingapp-default-rtdb.asia-southeast1.firebasedatabase.app',
      'assignedTrucks.json',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      List<Map<String, dynamic>> trucks = [];
      data.forEach((key, value) {
        Map<String, dynamic> truck = value;
        truck['key'] = key;
        truck['selectedDepartureDate'] = value['estimatedDepartureDate'];
        truck['selectedInboundPlace'] = value['inboundPlace'];
        truck['selectedOutboundPlace'] = value['outboundPlace'];

        trucks.add(truck);
      });

      return trucks;
    } else {
      throw Exception('Failed to fetch trucks from Firebase');
    }
  }

  // Delete a truck from Firebase
  Future<void> deleteTruckFromFirebase(Map<String, dynamic> truck) async {
    if (truck.containsKey('key')) {
      final truckId = truck['key'];
      final url = Uri.https(
        'hauliertrackingapp-default-rtdb.asia-southeast1.firebasedatabase.app',
        'assignedTrucks/$truckId.json', // Use $truckId to specify the specific truck
      );

      try {
        final response = await http.delete(url);

        if (response.statusCode == 200) {
          print('Truck deleted successfully');
          // Refresh the list of assigned trucks after deletion
          setState(() {
            assignedTrucks.remove(truck);
          });
        } else {
          print('Failed to delete truck. Status code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error: $error');
      }
    } else {
      print('Truck does not have a valid identifier (key)');
    }
  }

  // confirm delivery with a dialog
  void confirmDelivery(BuildContext context, Map<String, dynamic> truck) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delivery'),
          content: Text('Has the truck completed its delivery?'),
          actions: [
            TextButton(
              onPressed: () {
                // Delete the truck from the database and update UI
                if (truck != null && truck.containsKey('key')) {
                  print('Deleting truck with key: ${truck['key']}');
                  deleteTruckFromFirebase(truck);
                } else {
                  print('Invalid truck data. Unable to delete. Truck: $truck');
                }
                // Refresh the list after deletion
                fetchAssignedTrucksFromFirebase().then((updatedTrucks) {
                  onTrucksScheduled(updatedTrucks);
                });
                Navigator.of(context).pop();
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Update the list of assigned trucks
  void onTrucksScheduled(List<Map<String, dynamic>> scheduledTrucks) {
    // Update the list of assigned trucks
    setState(() {
      assignedTrucks = scheduledTrucks;
    });
  }
}
