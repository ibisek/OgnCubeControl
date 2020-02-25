
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
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

  void onConnectIconClick(context) async {
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

        return;
      }

      terminal.clear();
      printToTerminal("Connecting to '${BTManager().selectedDevice.name}'..");
      bool res = await BTManager().connectTo(BTManager().selectedDevice);
      if (!res) {
        printToTerminal("  Connection failed.\n  Cannot continue.");
        return;
      }

      printToTerminal("  Success! :)");
    }

    // flip the state:
    setState(() {
      btDeviceConnected = BTManager().isConnected();
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
    //TODO print firmware target, version and filename to console

    btDeviceConnected = BTManager().isConnected();  // get current actual state

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

  void printToTerminal(String str) {
    terminal.text += "$str\n";
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
      fw.bytes = response.bodyBytes;

      // TODO store firmware locally
      // firmware.isStoredLocally = true;

      return true;
    }

    return false;
  }

  /// Sends a COMMAND to unit and awaits for EXPECTed string in the line.
  /// @param cmd: command either as String or Uint8List
  /// @param expect: a string to expect in the response line
  /// @param delayMs: optional, default 400ms
  Future<String> queryTheUnit(dynamic cmd, String expect, {int delayMs=400}) async {
    BTManager btm = BTManager();

    btm.clearBuffer();
    if (cmd is String)  btm.writeStr(cmd);
    else if (cmd is Uint8List) btm.writeBytes(cmd);
    else {
      print("[ERROR] Wrong CMD argument type!");
      return null;
    }

    await Future.delayed(new Duration(milliseconds: delayMs)); // give it some time

    String response;

    int maxLoops = 123;
    do {
      response = btm.readLine();
    } while(--maxLoops > 0 && (response == null || response.indexOf(expect) < 0));

    if (maxLoops > 0) return response;
    else return null;
  }

  void flashFirmware() async {
    if(!BTManager().isConnected()) {
      printToTerminal("Not connected!");
      return;
    }

    printToTerminal("All right, hold my beer..");

    if(firmware != null && firmware.bytes == null) {
      printToTerminal("Downloading file '${firmware.filename}'..");
      bool res = await downloadFirmware(firmware);
      if (!res) {
        printToTerminal("  Connection failed.\n  Cannot continue.");
        return;

      } else {
        printToTerminal("  this is good.");
      }
    }

    printToTerminal("And now the fun begins!");

    // get OGN id from the BT device name:
    String btDeviceName = BTManager().connectedDevice.name;
    RegExp re = new RegExp(r'(\d{6})');
    var match = re.firstMatch(btDeviceName);
    String ognIdStr = btDeviceName.substring(match.start, match.end);
    int ognId = int.parse(ognIdStr, radix: 16); // HEX str id to int
    //print("OGN id as str: ognIdStr");
    //print("OGN id in DEC: $cpuId");

    String resp = await queryTheUnit('\$CMDVER\n', '\$VER'); // $VER;CUBE3;021338;2020-02-19*59
    print("VER resp: $resp");
    if(resp.indexOf(ognIdStr) < 0) {  // check device ids match
      printToTerminal("Selected ('$ognIdStr') and remote ('${resp.split(';')[2]}') devices IDs do not match!");
      return;
    }

    resp = await queryTheUnit('\$CMDRST\n', 'seconds', delayMs: 5000); // ## serialLoader.f103 ##
    print("RST resp: $resp");

    resp = await queryTheUnit('\nPROG', 'CPU ID?');
    print("PROG resp: $resp");

    // convert String ID to '\n' + 3 bytes:
    Uint8List bytes = new Uint8List(4);  // these 4 bytes will contain '\nCPUID'
    var buffer = bytes.buffer;
    var bdata = new ByteData.view(buffer);
    bdata.setUint32(0, ognId);
    bytes[0] = '\n'.codeUnitAt(0);
    //print("OGN id as DEC bytes: $bytes");

    resp = await queryTheUnit(bytes, 'START ADDR?');  // expects '\n' + 3 bytes of lowest CPU id
    print("CPUID resp: $resp");

    bytes = new Uint8List(5);  // these 5 bytes will contain '\nADDR'
    buffer = bytes.buffer;
    bdata = new ByteData.view(buffer);
    bdata.setUint32(1, int.parse("08002800", radix: 16));  // 0x08002800
    bytes[0] = '\n'.codeUnitAt(0);
    //print("ADDR as DEC bytes: $bytes");

    resp = await queryTheUnit(bytes, 'LEN?');  // expects '\n' + 4 bytes 0x08002800 = 134227968 dec
    print("START ADDR resp: $resp");

    bytes = new Uint8List(4);
    buffer = bytes.buffer;
    bdata = new ByteData.view(buffer);
    bdata.setUint32(0, firmware.bytes.lengthInBytes);
    bytes[0] = '\n'.codeUnitAt(0);
    print("FW LEN ${firmware.bytes.lengthInBytes} B as DEC array: $bytes");

    resp = await queryTheUnit(bytes, 'OK'); // expects '\n' + 3 bytes while length % 4 == 0
    print("DATA LEN resp: $resp");

    // TODO flash process in a background thread..

  }

} // ~ class