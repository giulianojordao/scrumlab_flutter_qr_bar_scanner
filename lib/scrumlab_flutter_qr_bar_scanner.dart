import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

//class FlutterQrBarScanner {
//  static const MethodChannel _channel =
//      const MethodChannel('scrumlab_flutter_qr_bar_scanner');
//
//  static Future<String> get platformVersion async {
//    final String version = await _channel.invokeMethod('getPlatformVersion');
//    return version;
//  }
//}

class PreviewDetails {
  PreviewDetails(this.height, this.width, this.orientation, this.textureId);

  num height;
  num width;
  num orientation;
  int textureId;
}

enum BarcodeFormats {
  ALL_FORMATS,
  AZTEC,
  CODE_128,
  CODE_39,
  CODE_93,
  CODABAR,
  DATA_MATRIX,
  EAN_13,
  EAN_8,
  ITF,
  PDF417,
  QR_CODE,
  UPC_A,
  UPC_E,
}

const List<BarcodeFormats> _defaultBarcodeFormats = [
  BarcodeFormats.ALL_FORMATS,
];

// ignore: avoid_classes_with_only_static_members
class FlutterQrReader {
  static const MethodChannel _channel = MethodChannel(
      'com.github.contactlutforrahman/scrumlab_flutter_qr_bar_scanner');
  static QrChannelReader channelReader = QrChannelReader(_channel);
  //Set target size before starting
  static Future<PreviewDetails> start({
    @required int? height,
    @required int? width,
    @required QRCodeHandler? qrCodeHandler,
    List<BarcodeFormats>? formats = _defaultBarcodeFormats,
  }) async {
    final List<BarcodeFormats> _formats = formats ?? _defaultBarcodeFormats;
    assert(_formats.isNotEmpty);

    final List<String> formatStrings = _formats
        .map((BarcodeFormats format) => format.toString().split('.')[1])
        .toList(growable: false);

    channelReader.setQrCodeHandler(qrCodeHandler!);
    // ignore: always_specify_types
    final Map<dynamic, dynamic>? details =
        await _channel.invokeMethod('start', {
      'targetHeight': height,
      'targetWidth': width,
      'heartbeatTimeout': 0,
      'formats': formatStrings
    });

    // invokeMethod returns Map<dynamic,...> in dart 2.0
    assert(details is Map<dynamic, dynamic>);

    final int textureId = details!['textureId'] as int;
    final num orientation = details['surfaceOrientation'] as num;
    final num surfaceHeight = details['surfaceHeight'] as num;
    final num surfaceWidth = details['surfaceWidth'] as num;

    return PreviewDetails(surfaceHeight, surfaceWidth, orientation, textureId);
  }

  static Future<dynamic> stop() {
    channelReader.setQrCodeHandler((_) {});
    return _channel.invokeMethod<dynamic>('stop').catchError(print);
  }

  static Future<dynamic> heartbeat() {
    return _channel.invokeMethod<dynamic>('heartbeat').catchError(print);
  }

  static Future<List<List<int?>>?> getSupportedSizes() {
    return _channel
        .invokeMethod<List<List<int?>>?>('getSupportedSizes')
        .catchError(() {
      print('Error');
    });
  }
}

enum FrameRotation { none, ninetyCC, oneeighty, twoseventyCC }

typedef QRCodeHandler = void Function(String qr)?;

class QrChannelReader {
  QrChannelReader(this.channel) {
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'qrRead':
          if (qrCodeHandler != null) {
            assert(call.arguments is String);
            qrCodeHandler!(call.arguments as String);
          }
          break;
        default:
          print('QrChannelHandler: unknown method call received at '
              '${call.method}');
      }
    });
  }

  void setQrCodeHandler(QRCodeHandler qrch) {
    qrCodeHandler = qrch;
  }

  MethodChannel channel;
  QRCodeHandler qrCodeHandler;
}
