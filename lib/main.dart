import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(SensorApp());
}

class SensorApp extends StatefulWidget {
  @override
  _SensorAppState createState() => _SensorAppState();
}

class _SensorAppState extends State<SensorApp> {
  String temperature = "Loading...";
  String humidity = "Loading...";
  String ph = "Loading...";

  Future<void> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.5/sensor'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          temperature = "${data['temperature']} °C";
          humidity = "${data['humidity']} %";
          ph = "${data['ph']}";
        });
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
      setState(() {
        temperature = "Error";
        humidity = "Error";
        ph = "Error";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSensorData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Sprout")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Temperature: $temperature", style: TextStyle(fontSize: 20)),
              Text("Humidity: $humidity", style: TextStyle(fontSize: 20)),
              Text("pH Level: $ph", style: TextStyle(fontSize: 20)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchSensorData,
                child: Text("Refresh"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

