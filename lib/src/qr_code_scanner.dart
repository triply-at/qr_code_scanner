import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'types/barcode.dart';
import 'types/camera.dart';
import 'types/features.dart';
import 'types/status.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);
typedef PermissionSetCallback = void Function(QRViewController, bool);

class QRView extends StatefulWidget {
  static final _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview');

  static Future<bool> requestCameraPermission() async {
    try {
      var permissions =  await _channel.invokeMethod('requestPermissions');
      return permissions;
    } on PlatformException {
      return false;
    }
  }

  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.onPermissionSet,
    this.showNativeAlertDialog = false,
    this.overlay,
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        assert(showNativeAlertDialog != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;
  final PermissionSetCallback onPermissionSet;
  final bool showNativeAlertDialog;
  final ShapeBorder overlay;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(),
        if (widget.overlay != null)
          Container(
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
          )
        else
          Container(),
      ],
    );
  }

  Widget _getPlatformQrView() {
    Widget _platformQrView;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _platformQrView = AndroidView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: _CreationParams.fromWidget(0, 0).toMap(),
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onQRViewCreated == null) {
      return;
    }
    widget.onQRViewCreated(QRViewController._(
        id, widget.key, widget.onPermissionSet, widget.showNativeAlertDialog));
  }
}

class _CreationParams {
  _CreationParams({this.width, this.height});

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  final double width;
  final double height;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }
}

class QRViewController {
  QRViewController._(
    int id,
    GlobalKey qrKey,
    PermissionSetCallback onPermissionSet,
    bool showNativeAlertDialogOnError,
  ) : _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id') {
    _channel.setMethodCallHandler(
      (call) async {
        var args = call.arguments;
        switch (call.method) {
          case scanMethodCall:
            if (args != null) {
              _scanUpdateController.sink.add(args.toString());
            }
            break;
          case permissionMethodCall:
            await getSystemFeatures(); // if we have no permission all features will not be avaible
            if (args != null) {
              if (args as bool) {
                _cameraActive = true;
                _hasPermissions = true;
              } else {
                _hasPermissions = false;
                if (showNativeAlertDialogOnError) {
                  await showNativeAlertDialog();
                }
              }
              if (onPermissionSet != null) {
                onPermissionSet(this, args as bool);
              }
            }
            break;
        }
      },
    );
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = qrKey.currentContext.findRenderObject();
      _channel.invokeMethod('setDimensions',
          {'width': renderBox.size.width, 'height': renderBox.size.height});
    }
  }

  static const scanMethodCall = 'onRecognizeQR';
  static const permissionMethodCall = 'onPermissionSet';

  final MethodChannel _channel;

  final StreamController<String> _scanUpdateController =
      StreamController<String>();

  Stream<String> get scannedDataStream => _scanUpdateController.stream;

  bool _flashActive = false;

  bool _cameraActive = false;

  int _activeCamera = 0;

  SystemFeatures _features;

  SystemFeatures get systemFeatures => _features;

  bool _hasPermissions;

  bool get hasPermissions => _hasPermissions;

  bool get cameraActive => _cameraActive;

  bool get flashActive => _flashActive;

  Camera get activeCamera =>
      _activeCamera == null ? null : Camera.values[_activeCamera];

  Future<ReturnStatus> flipCamera() async {
    try {
      _activeCamera = await _channel.invokeMethod('flipCamera') as int;
      return ReturnStatus.success;
    } on PlatformException {
      return ReturnStatus.failed;
    }
  }

  Future<ReturnStatus> toggleFlash() async {
    try {
      _flashActive = await _channel.invokeMethod('toggleFlash') as bool;
      return ReturnStatus.success;
    } on PlatformException {
      return ReturnStatus.failed;
    }
  }

  Future<ReturnStatus> pauseCamera() async {
    try {
      var cameraPaused = await _channel.invokeMethod('pauseCamera') as bool;
      _cameraActive = !cameraPaused;
      return ReturnStatus.success;
    } on PlatformException {
      return ReturnStatus.failed;
    }
  }

  Future<ReturnStatus> resumeCamera() async {
    try {
      _cameraActive = await _channel.invokeMethod('resumeCamera');
      return ReturnStatus.success;
    } on PlatformException {
      return ReturnStatus.failed;
    }
  }

  Future<ReturnStatus> showNativeAlertDialog() async {
    try {
      await _channel.invokeMethod('showNativeAlertDialog');
      return ReturnStatus.success;
    } on PlatformException {
      return ReturnStatus.failed;
    }
  }

  Future<ReturnStatus> setAllowedBarcodeTypes(List<BarcodeTypes> list) async {
    try {
      await _channel.invokeMethod('setAllowedBarcodeFormats',
          list?.map((e) => e.asInt())?.toList() ?? []);
      return ReturnStatus.success;
    } on PlatformException {
      return ReturnStatus.failed;
    }
  }

  Future<SystemFeatures> getSystemFeatures() async {
    try {
      var features =
          await _channel.invokeMapMethod<String, dynamic>('getSystemFeatures');
      _features = SystemFeatures.fromJson(features);
      _activeCamera = features['activeCamera'];
      return _features;
    } on PlatformException {
      return null;
    }
  }

  void dispose() {
    _scanUpdateController.close();
  }
}
