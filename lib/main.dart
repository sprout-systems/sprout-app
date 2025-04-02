import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(SensorApp());

class SensorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SensorPage(),
    );
  }
}

class SensorPage extends StatefulWidget {
  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  String temperature = "Loading...";
  String humidity = "Loading...";
  String ph = "Loading...";
  bool _isPumpRunning = false;
  double desiredTemp = 25.0;
  String espIp = "192.168.43.10";
  final TextEditingController _tempController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getData();
    _tempController.text = desiredTemp.toString();
  }

  @override
  void dispose() {
    _tempController.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    try {
      final response = await http.get(Uri.parse('http://$espIp/sensor'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          temperature = "${data['temperature']?.toStringAsFixed(1) ?? 'N/A'} °C";
          humidity = "${data['humidity']?.toStringAsFixed(1) ?? 'N/A'} %";
          ph = data['ph']?.toStringAsFixed(2) ?? 'N/A';
          desiredTemp = data['desiredTemp']?.toDouble() ?? 25.0;
          _tempController.text = desiredTemp.toStringAsFixed(1);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> setTemperature() async {
    double? newTemp = double.tryParse(_tempController.text);

    try {
      await http.post(
        Uri.parse('http://$espIp/command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'desiredTemp': newTemp}),
      );
      setState(() => desiredTemp = newTemp ?? desiredTemp);
      getData();
    } catch (e) {
      print(e);
    }
  }

  Future<void> togglePump() async {
    if (_isPumpRunning) return;
    
    setState(() => _isPumpRunning = true);

    try {
      await http.post(
        Uri.parse('http://$espIp/command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pumpWater': true}),
      );
      
      await Future.delayed(Duration(seconds: 10));
      
      await http.post(
        Uri.parse('http://$espIp/command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pumpWater': false}),
      );
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isPumpRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sprout Control")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text("Temperature: $temperature", style: TextStyle(fontSize: 20)),
                    Text("Humidity: $humidity", style: TextStyle(fontSize: 20)),
                    Text("pH: $ph", style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tempController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Set Temperature',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: setTemperature,
                  child: Text("SET"),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isPumpRunning ? null : togglePump,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPumpRunning ? Colors.green : null,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(_isPumpRunning ? "PUMP ACTIVED" : "ACTIVATE PUMP"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: getData,
              child: Text("REFRESH DATA"),
            ),
          ],
        ),
      ),
    );
  }
}
