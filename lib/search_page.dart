import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleScanPage extends StatefulWidget {
  @override
  _BleScanPageState createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  List<ScanResult> _scanResults = [];

  Future<void> _requestPermissions() async {
    final bluetoothScanStatus = await Permission.bluetoothScan.status;
    final bluetoothConnectStatus = await Permission.bluetoothConnect.status;

    if (bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted) {
      _startScanning();
    } else {
      final bluetoothScanRequestResult =
      await Permission.bluetoothScan.request();
      final bluetoothConnectRequestResult =
      await Permission.bluetoothConnect.request();

      if (bluetoothScanRequestResult.isGranted &&
          bluetoothConnectRequestResult.isGranted) {
        _startScanning();
      } else {
        print('Permissions not granted for Bluetooth scanning and connection');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bluetooth permissions not granted'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  void _startScanning() async {
    setState(() {
      _scanResults.clear();
    });

    // Start scanning for 10 seconds
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    // Listen for scan results
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        // Avoid duplicate entries
        for (var result in results) {
          final exists = _scanResults.any(
                  (r) => r.device.remoteId == result.device.remoteId);
          if (!exists) _scanResults.add(result);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Beacons'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _requestPermissions,
            child: Text('Request Permissions & Scan'),
          ),
          SizedBox(height: 20),
          _scanResults.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                return ListTile(
                  title: Text(result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : 'Unknown Device'),
                  subtitle: Text(result.device.remoteId.str),
                  trailing: Text('${result.rssi} dBm'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
