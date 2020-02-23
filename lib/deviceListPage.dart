
import 'package:flutter/material.dart';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:app_settings/app_settings.dart';

import 'package:cube_control/btManager.dart';


class DeviceListPage extends StatefulWidget {

  static const routeName = '/deviceList';
  final String title;

  DeviceListPage({Key key, this.title}) : super(key: key);

  @override
  _DeviceListPageState createState() => _DeviceListPageState();
}

class DeviceListItem {
  String name;
  String address;

  DeviceListItem(this.name, this.address);
}

class _DeviceListPageState extends State<DeviceListPage> {

  List<DeviceListItem> pairedDevices = List();

  @override
  void initState() {
    super.initState();
  }

  void refreshListView() async {
    await BTManager.instance.refresh();
    setState(() {
      populateListView();
    });
  }

  /// Populates list with paired BT dev. names/
  void populateListView() async {
    pairedDevices.clear();
    if(BTManager.instance.pairedBtDevices.length > 0) {
//      selectedIndex = BTManager.instance  // TODO restore selected index

      for(BluetoothDevice dev in BTManager.instance.pairedBtDevices) {
        if(dev.name != null && dev.name.isNotEmpty) pairedDevices.add(new DeviceListItem(dev.name, dev.address));
        else pairedDevices.add(new DeviceListItem(dev.address, null));
      }

    } else {
      pairedDevices.add(new DeviceListItem('Bluetooth is disabled', 'Go to settings to enable it.'));
    }
  }

  IconData getListSelectionIcon(index) {
    if (!BTManager.instance.btAvailable) return Icons.bluetooth_disabled;
    if (BTManager.instance.selectedIndex == index) return Icons.radio_button_checked;
    else return Icons.radio_button_unchecked;
  }

  Widget getRow(int i) {
    Row row = Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(left: 10, right: 20),   //all(8),
          child: Icon(getListSelectionIcon(i)),
        ),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(pairedDevices[i].name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(pairedDevices[i].address != null ? pairedDevices[i].address : "",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
      ],
    );

    Container c = Container(
      padding: const EdgeInsets.all(8),
      height: 60,
      child: row,
    );

    return c;
  }

  Widget getProgressDialog() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          Text('\nRetrieving paired BT devices..'),
        ],
      ),
    );
  }

  ListView getListView(BuildContext context) {
    return ListView.separated(
      itemCount: pairedDevices.length,
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
    if (pairedDevices.length == 0) {
      refreshListView();
      return getProgressDialog();

    } else
      return getListView(context);
  }

  @override
  Widget build(BuildContext context) {
    BTManager().refresh();

    return Scaffold (
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'clear log area',
            onPressed: onSettingsIconTap,
          ),
        ],
      ),
      body: getBody(),
//      floatingActionButton: FloatingActionButton.extended(
//        onPressed: refreshListView,
//        tooltip: 'Refresh',
//        icon: Icon(Icons.refresh),
//      ),
    );
  }

  void onSettingsIconTap() {
    AppSettings.openBluetoothSettings();
  }

  void onListItemTap(int index) {
    setState(() {
      BTManager().setSelectedIndex(index);
    });

    Navigator.pop(context); // go back where we came from
  }
}

