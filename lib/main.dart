import 'appDrawer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cube_control/btManager.dart';
import 'package:cube_control/firmwareManager.dart';
import 'package:cube_control/logbookPage.dart';
import 'package:cube_control/firmware.dart';
import 'package:cube_control/firmwareUpdatePage.dart';
import 'package:cube_control/deviceListPage.dart';
import 'package:flutter_html/flutter_html.dart';


void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OGN Cube Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Available Firmwares'),
      routes: <String, WidgetBuilder>{
        MyHomePage.routeName:(BuildContext context) =>
            MyHomePage(title: 'Available Firmwares'),
        FirmwareUpdatePage.routeName: (BuildContext context) =>
            FirmwareUpdatePage(title: 'Firmware Upload'),
        DeviceListPage.routeName: (BuildContext context) =>
            DeviceListPage(title: 'Paired Devices'),
        LogbookPage.routeName: (BuildContext context) =>
            LogbookPage(title: 'Logbook'),

      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  static const routeName = '/firmwaresList';

  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {

  bool showProgressDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // Observes the app state. Detects application shutdown.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (BTManager().isConnected()) BTManager().disconnect();
    }
  }

  Widget getProgressDialog(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          //LinearProgressIndicator(),
          Text(text),
        ],
      ),
    );
  }

  Widget getRow(int i) {
    List<Firmware> firmwares = FirmwareManager().firmwares;

    Row row = Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(left: 4, right: 10), //all(8),
          child: Icon(FirmwareManager().firmwares[i].isStoredLocally
              ? Icons.sd_storage
              : Icons.cloud_queue),
        ),
        Expanded(
          child: Html(
            data: "${firmwares[i].type} | <b>${firmwares[i].date}</b><br>${firmwares[i].title}",
          ),
        ),
        Icon(Icons.keyboard_arrow_right), //cloud_download | save_alt
      ],
    );

    Container c = Container(
      padding: const EdgeInsets.all(8),
      height: 50,
      child: row,
    );

    return c;
  }

  ListView getListView(BuildContext context) {
    return ListView.separated(
      itemCount: FirmwareManager().firmwares.length,
      itemBuilder: (BuildContext context, int index) {
        return new GestureDetector(
          onTap: () => onListItemTap(index),
          onLongPress: () => onListItemLongPress(index),
          child: getRow(index),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  Widget getBody() {
    if (FirmwareManager().firmwares.length == 0)
      return getProgressDialog('\nLoading..');
    else if (showProgressDialog)
      return getProgressDialog('\nChecking on newest firmwares..');
    else
      return getListView(context);
  }

  void onListItemTap(index) {
    Navigator.of(context).
      pushNamed(FirmwareUpdatePage.routeName, arguments: FirmwareManager().firmwares[index]);
  }

  void onListItemLongPress(index) async {
    List<Firmware> firmwares = FirmwareManager().firmwares;

    String typeCaption;
    switch(firmwares[index].type) {
      case 'TOW':
        typeCaption = "tow planes";
        break;
      case 'UAV':
        typeCaption = "UAVs";
        break;
      case 'GLD':
        typeCaption = "gliders";
        break;
    }

    await showDialog<String> (
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Firmware details'),
          children: <Widget>[
            Container(
            padding: const EdgeInsets.only(left: 10, right: 10), //all(8),
            child: Html(
              data: """
                <table>
                  <tr>
                    <td>Release date:</td>
                    <td colspan='2'>${firmwares[index].date}</td>
                  </tr>
                  <tr>
                    <td>Intended for:</td>
                    <td colspan='2'>$typeCaption</td>
                  </tr>
                  <tr>
                    <td>Title:</td>
                    <td colspan='2'>${firmwares[index].title}</td>
                  </tr>
                  <tr>
                    <td style='vertical-align:top;'>Description:</td>
                    <td colspan='2'>${firmwares[index].notes}</td>
                  </tr>
                  <tr>
                    <td>File size:</td>
                    <td colspan='2'>${firmwares[index].len} bytes</td>
                  </tr>
                </table>
              """,
              ),
            ),
          ],
        );
      }
    );
  }

  void onHelpIconClick(context) async {
//    Scaffold.of(context).showSnackBar(SnackBar(
//      content: Text("Long press the items to view details"),
//      ),
//    );

    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: "Long press the items to view details",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
    );
  }

  void onRefreshFirmwareListClicked() async {
    setState(() {
      showProgressDialog = true;
    });

    FirmwareManager fwm = FirmwareManager();
    bool listDownloaded = await fwm.downloadFirmwareList();

    if(!listDownloaded) {
      Fluttertoast.showToast(
        msg: 'Can not reload firmware list.\nAre you online?',
        toastLength: Toast.LENGTH_LONG,
      );
    }

    setState(() {
      showProgressDialog = false;
    });
  }

  /// This is a delayed builder which gets called after
  /// firwares are loaded from the local storage.
  Widget _build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Builder(  // this is here to get the right 'context' for the onPressed action
            builder: (context) =>
                Center(
                  child:
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    tooltip: 'instructions',
                    onPressed: () => onHelpIconClick(context),
                  ),
                ),
          ),
        ],
      ),
      drawer: getAppDrawer(context),
      body: getBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: onRefreshFirmwareListClicked,
        tooltip: 'Reload',
        child: Icon(Icons.cached),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder (
      future: FirmwareManager.instance.init(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.done) {
          return _build(context);
        } else {
          return _build(context);
        }
      },
    );
  }
}
