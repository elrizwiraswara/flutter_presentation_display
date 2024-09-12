import 'package:flutter/material.dart';
import 'package:flutter_presentation_display/display.dart';
import 'package:flutter_presentation_display/flutter_presentation_display.dart';

/// Main Screen
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  FlutterPresentationDisplay displayManager = FlutterPresentationDisplay();
  List<Display?> displays = [];

  final TextEditingController _indexToShareController = TextEditingController();
  final TextEditingController _dataToTransferController =
      TextEditingController();

  final TextEditingController _nameOfIdController = TextEditingController();
  String _nameOfId = "";
  final TextEditingController _nameOfIndexController = TextEditingController();
  String _nameOfIndex = "";

  dynamic dataFromPresentation;

  @override
  void initState() {
    displayManager.connectedDisplaysChangedStream.listen((event) {
      debugPrint("connected displays changed: $event");
    });

    displayManager.listenDataFromPresentationDisplay(onDataReceived);
    super.initState();
  }

  void onDataReceived(dynamic data) {
    debugPrint('received data from presentation display: $data');
    dataFromPresentation = data;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _getDisplays(),
              _showPresentation(),
              _hidePresentation(),
              _transferData(),
              _dataFromPresentation(),
              _getDisplayeById(),
              _getDisplayByIndex(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getDisplays() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            child: const Text('Get Displays'),
            onPressed: () async {
              final values = await displayManager.getDisplays();
              displays.clear();
              displays.addAll(values!);
              setState(() {});
            },
          ),
          ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: displays.length,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 50,
                child: Center(
                    child: Text(
                        ' ${displays[index]?.displayId} ${displays[index]?.name}')),
              );
            },
          ),
          const Divider()
        ],
      ),
    );
  }

  Widget _showPresentation() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _indexToShareController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Index to share screen',
              ),
            ),
          ),
          ElevatedButton(
            child: const Text('Show presentation'),
            onPressed: () async {
              int? displayId = int.tryParse(_indexToShareController.text);
              if (displayId != null) {
                for (final display in displays) {
                  if (display?.displayId == displayId) {
                    displayManager.showSecondaryDisplay(
                        displayId: displayId, routerName: "presentation");
                  }
                }
              }
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _hidePresentation() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _indexToShareController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Index to hide screen',
              ),
            ),
          ),
          ElevatedButton(
            child: const Text('Hide presentation'),
            onPressed: () async {
              int? displayId = int.tryParse(_indexToShareController.text);
              if (displayId != null) {
                for (final display in displays) {
                  if (display?.displayId == displayId) {
                    displayManager.hideSecondaryDisplay(displayId: displayId);
                  }
                }
              }
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _transferData() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _dataToTransferController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Data to transfer',
              ),
            ),
          ),
          ElevatedButton(
            child: const Text('Transfer Data to presentation'),
            onPressed: () async {
              String data = _dataToTransferController.text;
              await displayManager.transferDataToPresentation(data);
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _dataFromPresentation() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Text('Data from presentation: ${dataFromPresentation ?? '-'}'),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _getDisplayeById() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameOfIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Id',
              ),
            ),
          ),
          ElevatedButton(
            child: const Text('Name By Display Id'),
            onPressed: () async {
              int? id = int.tryParse(_nameOfIdController.text);
              if (id != null) {
                final value = await displayManager
                    .getNameByDisplayId(displays[id]?.displayId ?? -1);
                _nameOfId = value ?? "";
                setState(() {});
              }
            },
          ),
          SizedBox(
            height: 50,
            child: Center(child: Text(_nameOfId)),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _getDisplayByIndex() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameOfIndexController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Index',
              ),
            ),
          ),
          ElevatedButton(
            child: const Text('Name By Index'),
            onPressed: () async {
              int? index = int.tryParse(_nameOfIndexController.text);
              if (index != null) {
                final value = await displayManager.getNameByIndex(index);
                _nameOfIndex = value ?? "";
                setState(() {});
              }
            },
          ),
          SizedBox(
            height: 50,
            child: Center(child: Text(_nameOfIndex)),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
