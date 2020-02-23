
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'package:cube_control/firmware.dart';
import 'package:cube_control/btManager.dart';


class FirmwareUpdatePage extends StatefulWidget {
  FirmwareUpdatePage({Key key, this.title}) : super(key: key);

  static const routeName = '/firmwareUpdate';

  final String title;

  @override
  _FirmwareUpdatePageState createState() => _FirmwareUpdatePageState();
}

class _FirmwareUpdatePageState extends State<FirmwareUpdatePage> {

  var terminal = TextEditingController();
  bool btDeviceConnected = true;
  List<BluetoothDevice> pairedBtDevices;

  @override
  void initState() {
    super.initState();
    btDeviceConnected = BTManager().isConnected();
//    logArea.text += "Target type: ${firmware.type}\nRelease date: ${firmware.date}\nFile name: ${firmware.filename}";
  }

  void onDeleteIconClick() {
    terminal.clear();
  }

  void onConnectIconClick(context) async {
    if(btDeviceConnected) {
      BTManager().disconnect();

    } else {
      if (BTManager().selectedDevice == null) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("No bluetooth device selected!"),
          action: SnackBarAction(
            label: 'Fix it!',
            onPressed: () { print('## GO TO SHOW DEVICES SCREEN ##'); /*TODO navigate to device select screen*/ },
            ),
          ),
        );

        return;
      }

      bool res = await BTManager().connectTo(BTManager().selectedDevice);
      if (!res) {
        Fluttertoast.showToast(
          msg: "Connection failed",
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    }

    // flip the state:
    setState(() {
      btDeviceConnected = !btDeviceConnected;
    });
  }

  void onHelpIconClick() {
    print("Heeelp !!");
    // TODO popup okno s instrukcema co, jak a proc to tak funguje
  }

  @override
  Widget build(BuildContext context) {
    // pop-up the argumens sent from the previous page:
    final Firmware firmware = ModalRoute
        .of(context)
        .settings
        .arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Builder(  // this is here to get the right 'context' for the onPressed action
            builder: (context) =>
              Center(
                child: IconButton(
                    icon: Image(
                      image: btDeviceConnected ? AssetImage('assets/images/ic_connected.png') : AssetImage('assets/images/ic_disconnected.png'),
                    ),
                    tooltip: 'bt device connection status',
                    onPressed: () => onConnectIconClick(context),
                  ),
              ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'clear log area',
            onPressed: onDeleteIconClick,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'instructions',
            onPressed: onHelpIconClick,
          ),
        ],
      ),

      body: Center(
        child: Container(
//          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
//              Row(
//                children: <Widget>[
//                  Text(
//                    "Target type: ${firmware.type}\nRelease date: ${firmware
//                        .date}\nFile name: ${firmware.filename}",
//                    softWrap: true,
//                    textAlign: TextAlign.left,
//                    textScaleFactor: 1.0,),
//                ],
//              ),
              Expanded(
                child: Container(
//                  color: Colors.black,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      child: TextField(
                        controller: terminal,
                        keyboardType: TextInputType.multiline,
                        maxLines: null, //grow automatically
                        textAlign: TextAlign.left,
                        decoration: InputDecoration.collapsed(
                            hintText: "Info about update process will appear here.."
                        ),
                        style: TextStyle(color: Colors.green, /*fontFamily: 'Courier',*/),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: flashFirmware,
        tooltip: 'Flash firmware',
        icon: Icon(Icons.bluetooth_audio),
        label: Text('START'),
      )
    );
  }

  void printToTerminal(String str) {
    terminal.text += "$str\n";
  }

  void flashFirmware() async {
    if(!btDeviceConnected) {
      Fluttertoast.showToast(
        msg: "Not connected!",
        toastLength: Toast.LENGTH_SHORT,
      );

      return;
    }

    printToTerminal("All right, hold my beer..\n");

    // TODO flash process in a background thread..

//    var btAvailable = await FlutterBluetoothSerial.instance.isAvailable;
//    print("btAvailable: $btAvailable");
//    if(btAvailable) {
//      pairedBtDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
//      print("LLL: $pairedBtDevices");
//      for(BluetoothDevice dev in pairedBtDevices) {
//        logArea.text += "${dev.address} -> ${dev.name}\n";
//      }
//
//      BluetoothDevice dev = pairedBtDevices[2];
//
//      if(!dev.isConnected) {
//        try {
//          BluetoothConnection conn = await BluetoothConnection.toAddress(dev.address);
//          print("isConnected: ${conn.isConnected}");
//
//          conn.input.listen((data) {
//            String strData = "";
//            for (var i in data) strData += String.fromCharCode(i);
//            print("data: $strData");
//            logArea.text += strData;
//
//          }).onDone(() {
//            print("Disconnected by remote peer");
//          });
//
////          conn.output.add([0,1,3,4]); // TOTO posilani dat
//
//        } catch (exception) {
//          print('Error when connecting to device');
//        }
//      }
//    }
  }

} // ~ class