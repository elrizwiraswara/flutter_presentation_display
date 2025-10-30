import 'package:flutter/material.dart';
import 'package:flutter_presentation_display/flutter_presentation_display.dart';

/// UI of Presentation display
class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  PresentationScreenState createState() => PresentationScreenState();
}

class PresentationScreenState extends State<PresentationScreen> {
  final _displayManager = FlutterPresentationDisplay();
  final _dataToTransferController = TextEditingController();

  String dataFromMain = "";

  @override
  void initState() {
    _displayManager.listenDataFromMainDisplay(onDataReceived);
    super.initState();
  }

  void onDataReceived(dynamic data) {
    debugPrint('received data from main display: $data');
    dataFromMain = data;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _transferToMainButton(),
              _dataFromMain(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transferToMainButton() {
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
                labelText: 'Data',
              ),
            ),
          ),
          ElevatedButton(
            child: const Text('Transfer Data To Main'),
            onPressed: () async {
              await _displayManager.transferDataToMain(
                _dataToTransferController.text,
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _dataFromMain() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            child: Center(child: Text('Data from main: $dataFromMain')),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
