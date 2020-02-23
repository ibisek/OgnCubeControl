///
/// Manages all affairs regarding bluetooth.
/// Keeps list of paired devices.
/// Manages connection to selected device.
///
///
/// This is a singleton.
/// @see https://stackoverflow.com/questions/12649573/how-do-you-build-a-singleton-in-dart
///

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


class BTManager {
  BTManager._privateConstructor();
  static final BTManager instance = BTManager._privateConstructor();

  factory BTManager() {
    return instance;
  }

  bool btAvailable = false;
  List<BluetoothDevice> pairedBtDevices = List();
  BluetoothDevice selectedDevice, connectedDevice;
  BluetoothConnection connection;
  int selectedIndex = -1; // = none

  Future<bool> refresh() async {
    btAvailable = await FlutterBluetoothSerial.instance.isAvailable;
    print("[INFO] btAvailable: $btAvailable");

    if(btAvailable) {
      pairedBtDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
    }

    // TODO load lastly selected and used device & highlight it (in the list view)

    print("[INFO] btInit() finished");
    return true;
  }

  /// Connects to specified device.
  /// @return True if successful
  Future<bool> connectTo(BluetoothDevice dev) async {
    if (identical(dev, connectedDevice)) {
      return true;

    } else if(connectedDevice != null && connection.isConnected) {
      connection.close();
      connection = null;
    }


    try {
      connection = await BluetoothConnection.toAddress(dev.address);
      print("[INFO] isConnected: ${connection.isConnected}");
      connectedDevice = dev;

      return true;

    } catch (exception) {
      connectedDevice = null;
      print("[FAIL] Couldn't connect to '${dev.name}':"+exception.toString());
    }

    return false;
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    selectedDevice = pairedBtDevices[index];
  }

  /// @return True if current device (if even selected) is connected
  bool isConnected() {
    if(connectedDevice != null && connectedDevice.isConnected)
      return true;

    return false;
  }

  /// Disconnects currently connected BT device (if any).
  void disconnect() {
    if(connection != null && connection.isConnected)
      connection.close();
  }

} // ~ class
