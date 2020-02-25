import 'package:cube_control/btManager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:cube_control/firmware.dart';
import 'package:cube_control/firmwareUpdatePage.dart';
import 'package:cube_control/deviceListPage.dart';

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
        FirmwareUpdatePage.routeName: (BuildContext context) => FirmwareUpdatePage(title: 'Firmware Upload'),
        DeviceListPage.routeName: (BuildContext context) => DeviceListPage(title: 'Paired Devices'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  List firmwares = List();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadFirmwareList();
  }

  // Observes the app state. Detects application shutdown.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if(BTManager().isConnected()) BTManager().disconnect();
    }
  }

  Widget getProgressDialog() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          //LinearProgressIndicator(),
          Text('\nChecking available firmwares..'),
        ],
      ),
    );
  }

  Widget getRow(int i) {
    Row row = Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(left: 6, right: 8),   //all(8),
          child: Icon( firmwares[i].isStoredLocally ? Icons.sd_storage : Icons.cloud_queue),
        ),
        Text("${firmwares[i].type}\n${firmwares[i].date}",
            textAlign: TextAlign.left),
        Expanded(
          child: Text("${firmwares[i].title}", textAlign: TextAlign.center),
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
      itemCount: firmwares.length,
      itemBuilder: (BuildContext context, int index) {
        return new GestureDetector(
          onTap: () => onListItemTap(index),
          child: getRow(index),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  Widget getBody() {
    if (firmwares.length == 0)
      return getProgressDialog();
    else
      return getListView(context);
  }

  onListItemTap(index) {
    Navigator.of(context)
        .pushNamed(FirmwareUpdatePage.routeName, arguments: firmwares[index]);
  }

  void clearFirmwareList() {
    setState(() {
      firmwares.clear();
    });
  }

  loadFirmwareList() async {
    clearFirmwareList();

    String dataURL =
        "https://raw.githubusercontent.com/ibisek/ognCube/master/releases/firmwares.json";

    http.Response response;
    try {
      response = await http.get(dataURL);
    } catch (exception) {
      // nix
    }

    if (response != null && response.statusCode == 200) {
      setState(() {
        List jsonList = json.decode(response.body);
        while (jsonList.length > 0) {
          Map item = jsonList.removeAt(0);
          Firmware fw = Firmware.fromJson(item);
          firmwares.add(fw);

          fw.getTs(); // just to set the TS in the instance
        }

        // order by date desc (most recent at the top):
        firmwares.sort((a, b) => b.timestamp - a.timestamp);
      });
    } else {
      Fluttertoast.showToast(
        msg: "Can not load firmware list. Are you online?",
        toastLength: Toast.LENGTH_LONG,
      );

      // throw Exception('Failed to load firmware list');
    }
  }

  Widget getDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'OGN Cube Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings_bluetooth),
            title: Text('Paired devices'),
            onTap: () { Navigator.of(context).pushNamed(DeviceListPage.routeName); },
          ),
          ListTile(
            leading: Icon(Icons.system_update_alt),
            title: Text('Firmware updates'),
            selected: true,
            onTap: () { Navigator.pop(context); }, // close the drawer
          ),
//          ListTile(
//            leading: FlutterLogo(size: 40.0),
//            title: Text('My OGN Cubes'),
//            subtitle: Text('Select active bluetooth connection'),
//          ),
          ListTile(
            leading: Icon(Icons.library_books),
            title: Text('Logbook'),
            enabled: false,
          ),
          ListTile(
            leading: Icon(Icons.flight),
            title: Text('Flights'),
            enabled: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: getDrawer(),
      body: getBody(),
//      body: Center(
//        // Center is a layout widget. It takes a single child and positions it
//        // in the middle of the parent.
//        child: Column(
//          // Column is also a layout widget. It takes a list of children and
//          // arranges them vertically. By default, it sizes itself to fit its
//          // children horizontally, and tries to be as tall as its parent.
//          //
//          // Invoke "debug painting" (press "p" in the console, choose the
//          // "Toggle Debug Paint" action from the Flutter Inspector in Android
//          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
//          // to see the wireframe for each widget.
//          //
//          // Column has various properties to control how it sizes itself and
//          // how it positions its children. Here we use mainAxisAlignment to
//          // center the children vertically; the main axis here is the vertical
//          // axis because Columns are vertical (the cross axis would be
//          // horizontal).
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: <Widget>[
//            Text(
//              'You have pushed the button this many times:',
//            ),
//            Text(
//              '$_counter',
//              style: Theme.of(context).textTheme.display1,
//            ),
//            Text(
//              'Ahoj Nufu! :)\nJak se mas?'
//            ),
//            MaterialButton(
//              onPressed: () {},
//              child: Text('toto je tlacitko'),
//              padding: EdgeInsets.only(left: 100.0, right: 100.0),
//            ),
//          ],
//        ),
//      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadFirmwareList,
        tooltip: 'Reload',
        child: Icon(Icons.cached),
      ), // This trailing comma makes auto-formatting nicer for build methods.
//      floatingActionButton: FloatingActionButton(
//        onPressed: _decrementCounter,
//        tooltip:  'Decrement',
//        child: Icon(Icons.remove),
//      ),
    );
  }
}

//Future<Album> fetchAlbum() async {
//  final response = await http.get('https://jsonplaceholder.typicode.com/albums/2');
//
//  if (response.statusCode == 200) {
//    // If the server did return a 200 OK response, then parse the JSON.
//    return Album.fromJson(json.decode(response.body));
//
//  } else {
//    // If the server did not return a 200 OK response, then throw an exception.
//    throw Exception('Failed to load album');
//  }
//}
