import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:beacon_broadcast/beacon_broadcast.dart';

class BleController extends GetxController {
  final BeaconBroadcast _beaconBroadcast = BeaconBroadcast();

  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.locationWhenInUse.request().isGranted) {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }

    else {
      print("Required permissions not granted.");
    }
  }

  void startBroadcasting(String uid) {
    try {
      final formattedUUID = uidToUuid(uid);

      _beaconBroadcast
          .setUUID(formattedUUID)
          .setMajorId(1)
          .setMinorId(100)
          .setAdvertiseMode(AdvertiseMode.lowLatency)
          .setIdentifier('uuid')
          .setLayout(BeaconBroadcast.ALTBEACON_LAYOUT)
          .start();

      _beaconBroadcast.getAdvertisingStateChange().listen((isAdvertising) {
        print("Beacon advertising started? $isAdvertising");
      });

      print("Started broadcasting UID as UUID: $formattedUUID");
    }
    catch (e) {
      print("Error broadcasting UID: $e");
    }
  }

  void stopBroadcasting() {
    _beaconBroadcast.stop();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connecting) {
          print("Connecting to: ${device.platformName}");
        } else if (state == BluetoothConnectionState.connected) {
          print("Connected to: ${device.platformName}");
        } else if (state == BluetoothConnectionState.disconnected) {
          print("Disconnected from: ${device.platformName}");
        }
      });
    }
    catch (e) {
      print("Connection error: $e");
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  String uidToUuid(String uid) {
    final bytes = sha1.convert(utf8.encode(uid)).bytes.sublist(0, 16);
    return [
      _bytesToHex(bytes.sublist(0, 4)),
      _bytesToHex(bytes.sublist(4, 6)),
      _bytesToHex(bytes.sublist(6, 8)),
      _bytesToHex(bytes.sublist(8, 10)),
      _bytesToHex(bytes.sublist(10, 16)),
    ].join("-");
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
