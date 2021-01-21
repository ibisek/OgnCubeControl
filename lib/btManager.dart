///
/// Manages all affairs regarding bluetooth.
/// Keeps list of paired devices.
/// Manages connection to selected device.
///
///
/// This is a singleton.
/// @see https://stackoverflow.com/questions/12649573/how-do-you-build-a-singleton-in-dart
///

import 'package:flutter/cupertino.dart';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cube_control/cubeInterface.dart';


class BTManager {
  BTManager._privateConstructor();
  static final BTManager instance = BTManager._privateConstructor();

  var btDevDisconnectedNotification; // function to be called upon device disconnect

  factory BTManager() {
    return instance;
  }

  bool btEnabled = false;
  bool btAvailable = false;
  List<BluetoothDevice> pairedBtDevices = List();
  BluetoothDevice selectedDevice, connectedDevice;
  BluetoothConnection connection;
  int selectedIndex = -1; // = none

  Future<bool> refresh() async {
    btEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    btAvailable = await FlutterBluetoothSerial.instance.isAvailable;
    print("[INFO] btAvailable: $btAvailable");

    if(btEnabled && btAvailable) {
      try {
        pairedBtDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      } catch (ex) {
        print("[WARN] error when accessing BT bonded devices for the first time");
      }

      if(selectedDevice == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String mac = prefs.getString("selectedBtDeviceMac");

        if(mac != null) {
          int i = 0;
          for(BluetoothDevice dev in pairedBtDevices) {
            if( dev.address == mac ) {
              selectedDevice = dev;
              selectedIndex = i;
              break;
            }
            i++;
          }
          if(selectedDevice == null) {  // is not paired anymore or what?
            prefs.remove("selectedBtDeviceMac");
          }
        }
      }

    }

    print("[INFO] btInit() finished");
    return true;
  }

  /// Connects to specified device.
  /// @return True if successful
  Future<bool> connectTo(BluetoothDevice dev) async {
    if (dev == null)
      return false;

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

  void setSelectedIndex(int index) async {
    selectedIndex = index;
    selectedDevice = pairedBtDevices[index];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("selectedBtDeviceMac", selectedDevice.address);
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

  Future<String> readUntil(String terminationChar) async {
    while(rxDataBuffer.toString().indexOf('\n') < 0)
      await Future.delayed(new Duration(milliseconds: 100)); // give it some time

    int i = rxDataBuffer.toString().indexOf('\n');
    String response = rxDataBuffer.toString().substring(0, i);

    int startIndex = i+1;
    int endIndex = rxDataBuffer.length-1;
    if (endIndex - startIndex > 0) {
      String theRest = rxDataBuffer.toString().substring(startIndex, endIndex);
      rxDataBuffer.clear();
      rxDataBuffer.write(theRest);
    } else {
      rxDataBuffer.clear();
    }

    return response;
  }

} // ~ class
