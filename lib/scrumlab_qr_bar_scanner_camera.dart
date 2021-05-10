import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scrumlab_flutter_qr_bar_scanner/scrumlab_flutter_qr_bar_scanner.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

final WidgetBuilder _defaultNotStartedBuilder =
    (BuildContext context) => const Text('Carregando a Câmera...');
final WidgetBuilder _defaultOffscreenBuilder =
    (BuildContext context) => const Text('Câmera pausada');
final ErrorCallback _defaultOnError = (BuildContext context, Object error) {
  print('Erro ao scanear código de barras pela câmera: $error');
  return const Text('Erro lendo código de barras pela câmera');
};

typedef ErrorCallback = Widget Function(BuildContext context, Object error);

class QRBarScannerCamera extends StatefulWidget {
  QRBarScannerCamera({
    Key? key,
    required this.qrCodeCallback,
    required this.child,
    this.fit = BoxFit.cover,
    WidgetBuilder? notStartedBuilder,
    WidgetBuilder? offscreenBuilder,
    ErrorCallback? onError,
    required this.formats,
  })   : notStartedBuilder = notStartedBuilder ?? _defaultNotStartedBuilder,
        offscreenBuilder =
            offscreenBuilder ?? notStartedBuilder ?? _defaultOffscreenBuilder,
        onError = onError ?? _defaultOnError,
        super(key: key);

  final BoxFit fit;
  final ValueChanged<String> qrCodeCallback;
  final Widget? child;
  final WidgetBuilder notStartedBuilder;
  final WidgetBuilder offscreenBuilder;
  final ErrorCallback onError;
  final List<BarcodeFormats>? formats;

  @override
  QRBarScannerCameraState createState() => QRBarScannerCameraState();
}

class QRBarScannerCameraState extends State<QRBarScannerCamera>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => onScreen = true);
    } else {
      if (onScreen) {
        FlutterQrReader.stop();
      }
      setState(() {
        onScreen = false;
        _asyncInitOnce = null;
      });
    }
  }

  bool onScreen = true;
  Future<PreviewDetails>? _asyncInitOnce;

  Future<PreviewDetails> _asyncInit(num height, num width) async {
    final PreviewDetails previewDetails = await FlutterQrReader.start(
      height: height.toInt(),
      width: width.toInt(),
      qrCodeHandler: widget.qrCodeCallback,
      formats: widget.formats,
    );
    return previewDetails;
  }

  /// This method can be used to restart scanning
  ///  the event that it was paused.
  void restart() {
    (() async {
      await FlutterQrReader.stop();
      setState(() {
        _asyncInitOnce = null;
      });
    })();
  }

  /// This method can be used to manually stop the
  /// camera.
  void stop() {
    (() async {
      await FlutterQrReader.stop();
    })();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (_asyncInitOnce == null && onScreen) {
        _asyncInitOnce =
            _asyncInit(constraints.maxHeight, constraints.maxWidth);
      } else if (!onScreen) {
        return widget.offscreenBuilder(context);
      }

      // ignore: always_specify_types
      return FutureBuilder(
        future: _asyncInitOnce,
        builder: (BuildContext context, AsyncSnapshot<PreviewDetails> details) {
          switch (details.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return widget.notStartedBuilder(context);
            case ConnectionState.done:
              if (details.hasError) {
                debugPrint(details.error.toString());
                return widget.onError(context, details.error!);
              }
              final Widget preview = SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                child: Preview(
                  previewDetails: details.data!,
                  targetHeight: constraints.maxHeight,
                  targetWidth: constraints.maxWidth,
                  fit: widget.fit,
                ),
              );

              return Stack(
                children: <Widget>[
                  preview,
                  widget.child!,
                ],
              );

            default:
              throw AssertionError('${details.connectionState} não suportado.');
          }
        },
      );
    });
  }
}

class Preview extends StatelessWidget {
  Preview({
    required PreviewDetails previewDetails,
    required this.targetHeight,
    required this.targetWidth,
    required this.fit,
  })   : textureId = previewDetails.textureId,
        height = previewDetails.height.toDouble(),
        width = previewDetails.width.toDouble(),
        orientation = previewDetails.orientation;

  final double height;
  final double width;
  final double targetWidth, targetHeight;
  final int textureId;
  final num orientation;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    double frameHeight, frameWidth;

    return NativeDeviceOrientationReader(
      builder: (BuildContext context) {
        final NativeDeviceOrientation nativeOrientation =
            NativeDeviceOrientationReader.orientation(context);

        int baseOrientation = 0;
        if (orientation != 0 && (width > height)) {
          baseOrientation = orientation ~/ 90;
          frameHeight = height;
          frameWidth = width;
        } else {
          frameWidth = height;
          frameHeight = width;
        }

        int nativeOrientationInt;
        switch (nativeOrientation) {
          case NativeDeviceOrientation.landscapeLeft:
            nativeOrientationInt = Platform.isAndroid ? 3 : 1;
            break;
          case NativeDeviceOrientation.landscapeRight:
            nativeOrientationInt = Platform.isAndroid ? 1 : 3;
            break;
          case NativeDeviceOrientation.portraitDown:
            nativeOrientationInt = 2;
            break;
          case NativeDeviceOrientation.portraitUp:
          case NativeDeviceOrientation.unknown:
            nativeOrientationInt = 0;
        }

        return FittedBox(
          fit: fit,
          child: RotatedBox(
            quarterTurns: baseOrientation + nativeOrientationInt,
            child: SizedBox(
              height: frameHeight,
              width: frameWidth,
              child: Texture(textureId: textureId),
            ),
          ),
        );
      },
    );
  }
}
