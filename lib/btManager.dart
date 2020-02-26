///
/// Manages all affairs regarding bluetooth.
/// Keeps list of paired devices.
/// Manages connection to selected device.
///
///
/// This is a singleton.
/// @see https://stackoverflow.com/questions/12649573/how-do-you-build-a-singleton-in-dart
///


import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';


class BTManager {
  BTManager._privateConstructor();
  static final BTManager instance = BTManager._privateConstructor();

  var btDevDisconnectedNotification; // function to be called upon device disconnect

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
    if (identical(dev, connectedDevice) && connectedDevice.isConnected) {
      return true;

    } else if(connectedDevice != null && connection.isConnected) {
      connection.close();
      connection = null;
    }


    try {
      connection = await BluetoothConnection.toAddress(dev.address);
      print("[INFO] isConnected: ${connection.isConnected}");
      connectedDevice = dev;

      startListening(connection);

      return true;

    } catch (exception) {
      connectedDevice = null;
      print("[FAIL] Couldn't connect to '${dev.name}'. Exception: "+exception.toString());
    }

    return false;
  }

  StringBuffer rxDataBuffer = StringBuffer();

  void clearBuffer() {
    rxDataBuffer.clear();
  }

  void startListening(BluetoothConnection conn) {
    clearBuffer();

    conn.input.listen((data) {
      String strData = String.fromCharCodes(data);
      rxDataBuffer.write(strData);
      //print("[BUF LEN] ${rxDataBuffer.length} [RXL] $strData");

    }).onDone(() {
      print("[INFO] BT disconnected by remote peer");
      connectedDevice = null;

      if(btDevDisconnectedNotification != null) btDevDisconnectedNotification();
    });
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    selectedDevice = pairedBtDevices[index];
  }

  /// @return True if current device (if even selected) is connected
  bool isConnected() {
    if(connectedDevice != null && connection.isConnected)
      return true;

    return false;
  }

  /// Disconnects currently connected BT device (if any).
  void disconnect() {
    if(connection != null && connection.isConnected)
      connection.close();
  }

  bool writeStr(String str) {
    if(!connection.isConnected) return false;

    List<int> list = str.codeUnits;
    Uint8List bytes = Uint8List.fromList(list);

    return writeBytes(bytes);
  }

  bool writeBytes(Uint8List bytes) {
    connection.output.add(bytes);

    return true;
  }

  String readLine() {
    int i = rxDataBuffer.toString().indexOf('\n');
    if(i >= 0) {
      String line = rxDataBuffer.toString().substring(0, i+1);
      rxDataBuffer = StringBuffer(rxDataBuffer.toString().substring(i+1));
      return line;
    }

    return null;
  }

} // ~ class
