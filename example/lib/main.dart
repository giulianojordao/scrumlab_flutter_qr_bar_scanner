import 'package:flutter/material.dart';
import 'package:scrumlab_flutter_qr_bar_scanner/scrumlab_qr_bar_scanner_camera.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter QR/Bar Code Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter QR/Bar Code Reader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _qrInfo = 'Digitalizar o código de barras';
  bool _camState = false;

  void _qrCallback(String code) {
    setState(() {
      _camState = false;
      _qrInfo = code;
    });
  }

  void _scanCode() {
    setState(() {
      _camState = true;
    });
  }

  @override
  void initState() {
    _scanCode();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: _camState
          ? Center(
              child: SizedBox(
                height: 1000,
                width: 500,
                child: QRBarScannerCamera(
                  onError: (BuildContext context, Object error) => Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                  qrCodeCallback: (String code) {
                    _qrCallback(code);
                  },
                  formats: null,
                  child: null,
                ),
              ),
            )
          : Center(
              child: Text(_qrInfo),
            ),
    );
  }
}
