
import 'package:cube_control/cubeInterface.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import 'package:cube_control/firmware.dart';
import 'package:cube_control/btManager.dart';
import 'package:cube_control/deviceListPage.dart';


class FirmwareUpdatePage extends StatefulWidget {
  FirmwareUpdatePage({Key key, this.title}) : super(key: key);

  static const routeName = '/firmwareUpdate';

  final String title;

  @override
  _FirmwareUpdatePageState createState() => _FirmwareUpdatePageState();
}

class _FirmwareUpdatePageState extends State<FirmwareUpdatePage> {

  var terminal = TextEditingController();
  Firmware firmware;
  bool btDeviceConnected = false; // just for the connected icon state

  @override
  void initState() {
    super.initState();
//    logArea.text += "Target type: ${firmware.type}\nRelease date: ${firmware.date}\nFile name: ${firmware.filename}";
  }

  void onDeleteIconClick() {
    terminal.clear();
  }

  Future<bool> onConnectIconClick(context) async {
    await BTManager().refresh();

    if(!BTManager().btEnabled) {
      printToTerminal('Bluetooth disabled.');
      return false;
    }

    if(BTManager().isConnected()) {
      BTManager().disconnect();
      printToTerminal("Disconnected.");

    } else {
      if (BTManager().selectedDevice == null) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("No bluetooth device selected!"),
          action: SnackBarAction(
            label: 'Select',
            onPressed: () { Navigator.of(context).pushNamed(DeviceListPage.routeName); },
            ),
          ),
        );

        return false;
      }

      terminal.clear();
      printToTerminal("Connecting to '${BTManager().selectedDevice.name}'..");
      bool res = await BTManager().connectTo(BTManager().selectedDevice);
      if (!res) {
        printToTerminal("  Connection failed.\n  Cannot continue.");
        return false;
      }

      printToTerminal("  Success! :)");

      // read out current firmware version:
      String resp = await CubeInterface().query('\$CMDVER\n', '\$VER'); // $VER;CUBE3;021338;2020-02-19*59
      //print("VER resp: $resp");
      if(resp != null) {
        String currentVersion = resp.split(';')[3].split('*')[0];
        printToTerminal("  current firmware version: $currentVersion");

        int ts = DateTime.parse("$currentVersion 00:00:01Z").toUtc().millisecondsSinceEpoch;
        if(firmware.getTs() < ts)
          printToTerminal("\nWARNING:\nSelected fw is OLDER than the current one!\n");
      }
    }

    // flip the state:
    setState(() {
      btDeviceConnected = BTManager().isConnected();
    });

    return true;
  }

  /// Called by BTManager when bt devices disconnects itself.
  void onBtDevDisconnected() {
    setState(() {
      btDeviceConnected = false;
    });
  }

  void onHelpIconClick() {
    print("Heeelp !!");
    // TODO popup okno s instrukcema co, jak a proc to tak funguje
  }

  @override
  Widget build(BuildContext context) {
    // pop-up the argumens sent from the previous page:
    firmware = ModalRoute
        .of(context)
        .settings
        .arguments;

    btDeviceConnected = BTManager().isConnected();  // get current actual state
    BTManager().btDevDisconnectedNotification = onBtDevDisconnected;

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
//          IconButton(
//            icon: const Icon(Icons.delete),
//            tooltip: 'clear log area',
//            onPressed: onDeleteIconClick,
//          ),
//          IconButton(
//            icon: const Icon(Icons.help_outline),
//            tooltip: 'instructions',
//            onPressed: onHelpIconClick,
//          ),
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
                            hintText: "Info about the update process will appear here."
                        ),
                        style: TextStyle(color: Colors.black, /*fontFamily: 'Courier',*/),
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

  void printToTerminal(String str, {String endLine='\n'}) {
    terminal.text += "$str";
    if(endLine != null) terminal.text += endLine;
  }

  Future<bool> downloadFirmware(Firmware fw) async {
    http.Response response;
    try {
      response = await http.get(fw.url);
    } catch (exception) {
      // nix
    }

    if (response != null && response.statusCode == 200) {
      printToTerminal("  got ${response.contentLength} bytes");
      fw.setBytes(response.bodyBytes);

      // TODO store firmware locally
      // firmware.isStoredLocally = true;

      return true;
    }

    return false;
  }

  void flashFirmware() async {
    if(!BTManager().isConnected()) {
      bool res = await onConnectIconClick(context);
      if (!res) return;
    }

    printToTerminal("All right, hold my beer..");

    if(firmware != null && firmware.bytes == null) {
      printToTerminal("Downloading file '${firmware.filename}'..");
      bool res = await downloadFirmware(firmware);
      if (!res) {
        printToTerminal("  Connection failed.\n  Cannot proceed.");
        return;

      } else {
        printToTerminal("  this is good.");
      }
    }

    // get OGN id from the BT device name:
    String ognIdStr = CubeInterface().getOgnIdStr();
    int ognId = CubeInterface().getOgnId();
    //print("OGN id as str: ognIdStr");
    //print("OGN id in DEC: $cpuId");

    printToTerminal("Executing RST command now..");
    String resp = await CubeInterface().query(CubeInterface.CMD_RST, 'seconds', delayMs: 6000); // ## serialLoader.f103 ##
    print("RST resp: $resp");

    resp = await CubeInterface().query('\nPROG', 'CPU ID?');
    printToTerminal("PROG resp: $resp $ognIdStr");

    // convert String ID to '\n' + 3 bytes:
    Uint8List bytes = new Uint8List(4);  // these 4 bytes will contain '\nCPUID'
    var buffer = bytes.buffer;
    var bdata = new ByteData.view(buffer);
    bdata.setUint32(0, ognId);
    bytes[0] = '\n'.codeUnitAt(0);
    //print("OGN id as DEC bytes: $bytes");

    resp = await CubeInterface().query(bytes, 'START ADDR?');  // expects '\n' + 3 bytes of lowest CPU id
    printToTerminal("CPUID resp: $resp 0x08002800");

    bytes = new Uint8List(5);  // these 5 bytes will contain '\nADDR'
    buffer = bytes.buffer;
    bdata = new ByteData.view(buffer);
    bdata.setUint32(1, int.parse("08002800", radix: 16));  // 0x08002800
    bytes[0] = '\n'.codeUnitAt(0);
    //print("ADDR as DEC bytes: $bytes");

    resp = await CubeInterface().query(bytes, 'LEN?');  // expects '\n' + 4 bytes 0x08002800 = 134227968 dec
    printToTerminal("START ADDR resp: $resp ${firmware.bytes.lengthInBytes}");

    bytes = new Uint8List(4);
    buffer = bytes.buffer;
    bdata = new ByteData.view(buffer);
    bdata.setUint32(0, firmware.bytes.lengthInBytes);
    bytes[0] = '\n'.codeUnitAt(0);
    //print("FW LEN ${firmware.bytes.lengthInBytes} B as DEC array: $bytes");

    resp = await CubeInterface().query(bytes, 'OK'); // expects '\n' + 3 bytes while length % 4 == 0
    printToTerminal("DATA LEN resp: $resp");

    printToTerminal("Data transfer: ");
    // transfer data in 1kB blocks
    const int BLOCK_SIZE = 1024;
    int i = 0;
    bool lastBlock = false;
    while (!lastBlock) {
      if ((i+1)*BLOCK_SIZE < firmware.bytes.lengthInBytes) {
        bytes = firmware.bytes.sublist(i*BLOCK_SIZE, (i+1) * BLOCK_SIZE);
      } else {
        bytes = firmware.bytes.sublist(i*BLOCK_SIZE, firmware.bytes.lengthInBytes);
        lastBlock = true;
      }

      bool res = BTManager().writeBytes(bytes);
      if(res) printToTerminal('#', endLine: null);  // 1kB / # progressbar
      else printToTerminal('X', endLine: null);

      // give the uC time to store the bytes into flash; yes - it really needs this time:
      if(!lastBlock) {
        await Future.delayed(new Duration(milliseconds: 900));
        i++; // nearly the most import thing here ;)
      }
    }
    printToTerminal(''); // newline after the "progress bar"

    resp = await CubeInterface().query(bytes, "CRC", delayMs: 2000);  // CRC:237
    printToTerminal("CRC resp: $resp");
    if(resp != null) {
      int ucCRC = int.parse(resp.trim().substring(resp.indexOf(':') + 1));
      if(ucCRC == firmware.crc) {
        printToTerminal("Firmware CRC: ${firmware.crc}. This is a match.\n\nWe are done! :)");
      } else {
        printToTerminal("Firmware CRC: ${firmware.crc}. This is wrong. Try reflashing.");
      }

    } else {
      print("No reponse. Something went wrong.");
    }
  }

} // ~ class