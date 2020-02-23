
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'package:cube_control/firmware.dart';


class FirmwareUpdatePage extends StatefulWidget {
  FirmwareUpdatePage({Key key, this.title}) : super(key: key);

  static const routeName = '/extractArguments';

  final String title;

  @override
  _FirmwareUpdatePageState createState() => _FirmwareUpdatePageState();
}

class _FirmwareUpdatePageState extends State<FirmwareUpdatePage> {

  var logArea = TextEditingController();

  List<DropdownMenuItem<String>> dropDownMenuItems;
  String dropDownMenuSelectedItem;
  List<BluetoothDevice> pairedBtDevices;

  @override
  void initState() {
    super.initState();
    dropDownMenuItems = getDropDownMenuItems();
    dropDownMenuSelectedItem = dropDownMenuItems[0].value;
  }

  List _cities = ["Cluj-Napoca", "Bucuresti", "Timisoara", "Brasov", "Constanta"];

  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = new List();
    for (String city in _cities) {
      items.add(new DropdownMenuItem(
          value: city,
          child: new Text(city)
      ));
    }
    return items;
  }

  void onDropDownItemChanged(String selectedCity) {
    print("Selected city $selectedCity, we are going to refresh the UI");
    setState(() {
      dropDownMenuSelectedItem = selectedCity;
    });
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
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      "Target type: ${firmware.type}\nRelease date: ${firmware
                          .date}\nFile name: ${firmware
                          .filename}\nurl: ${firmware.url}",
                      textAlign: TextAlign.left, textScaleFactor: 1.2,),
                    Text("${firmware.type}", textAlign: TextAlign.left),
                  ],
                ),
                DropdownButton<String> (
                    value: dropDownMenuSelectedItem,
                    items: dropDownMenuItems,
                    onChanged: onDropDownItemChanged,
                    icon: Icon(Icons.keyboard_arrow_down),
                    iconSize: 36,
                    elevation: 20,
//                    style: TextStyle(
//                        color: Colors.deepPurple
//                    ),
//                    underline: Container(
//                      height: 2,
//                      color: Colors.deepPurpleAccent,
//                    ),
                ),
                Card(
                  color: Colors.white24,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: TextField(
                      maxLines: 16,
                      decoration: InputDecoration.collapsed(
                          hintText: "Progress will appear here.."),
                      controller: logArea,
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () {
                        logArea.clear();
                      },
                      child: Text('[ CLEAR ]'),
                      padding: EdgeInsets.only(left: 10.0, right: 10.0),
                      color: Colors.blue,
                      textColor: Colors.white,
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                    ),
                    RaisedButton(
                      //onPressed: showResults,
                      child: Text('[ SHOW ]'),
                      padding: EdgeInsets.only(left: 10.0, right: 10.0),
                      color: Colors.blue,
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: flashFirmware,
          tooltip: 'Flash firmware',
          icon: Icon(Icons.bluetooth_audio),
          label: Text('Scan'),
        )
    );
  }

  void flashFirmware() async {
    print("doing stuff");

    logArea.text = "Scanning..\n";

    var btAvailable = await FlutterBluetoothSerial.instance.isAvailable;
    print("btAvailable: $btAvailable");
    if(btAvailable) {
      pairedBtDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      print("LLL: $pairedBtDevices");
      for(BluetoothDevice dev in pairedBtDevices) {
        logArea.text += "${dev.address} -> ${dev.name}\n";
      }

      BluetoothDevice dev = pairedBtDevices[2];

      if(!dev.isConnected) {
        try {
          BluetoothConnection conn = await BluetoothConnection.toAddress(dev.address);
          print("isConnected: ${conn.isConnected}");

          conn.input.listen((data) {
            String strData = "";
            for (var i in data) strData += String.fromCharCode(i);
            print("data: $strData");
            logArea.text += strData;

          }).onDone(() {
            print("Disconnected by remote peer");
          });

//          conn.output.add([0,1,3,4]); // TOTO posilani dat

        } catch (exception) {
          print('Error when connecting to device');
        }
      }
    }
  }

} // ~ class