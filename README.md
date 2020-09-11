# QR Code Scanner
[![GH Actions](https://github.com/juliuscanute/qr_code_scanner/workflows/dart/badge.svg)](https://github.com/juliuscanute/qr_code_scanner/actions)

A QR code scanner that works on both iOS and Android by natively embedding the platform view within Flutter. The integration with Flutter is seamless, much better than jumping into a native Activity or a ViewController to perform the scan.


## Screenshots
<table>
<tr>
<th colspan="2">
Android
</th>
</tr>

<tr>
<td>
<p align="center">
<img src="https://github.com/juliuscanute/qr_code_scanner/blob/master/.resources/android-app-screen-one.jpg" width="30%" height="30%">
</p>
</td>
<td>
<p align="center">
<img src="https://github.com/juliuscanute/qr_code_scanner/blob/master/.resources/android-app-screen-two.jpg" width="30%" height="30%">
</p>
</td>
</tr>

<tr>
<th colspan="2">
iOS
</th>
</tr>

<tr>
<td>
<p align="center">
<img src="https://github.com/juliuscanute/qr_code_scanner/blob/master/.resources/ios-app-screen-one.png" width="30%" height="30%">
</p>
</td>
<td>
<p align="center">
<img src="https://github.com/juliuscanute/qr_code_scanner/blob/master/.resources/ios-app-screen-two.png" width="30%" height="30%">
</p>
</td>
</tr>

</table>

## Get Scanned QR Code

When a QR code is recognized, the text identified will be set in 'qrText'.

```dart
class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var qrText = "";
  QRViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text('Scan result: $qrText'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
```

## iOS Integration
In order to use this plugin, add the following to your Info.plist file:
```
<key>io.flutter.embedded_views_preview</key>
<true/>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
```

## Get a callback if camera permissions are set
```
QRView(
      onPermissionSet: (QRViewController controller, bool permission){
      },
    ),
```

## Call native alert dialog (Android and IOS) if you dont have permissions
```dart
controller.showNativeAlertDialog();
```

## Call native alert dialog automatically if no permission is granted
```dart
QRView(
      showNativeAlertDialog: true, 
    ),
```

## Flip Camera (Back/Front)
The default camera is the back camera.
```dart
await controller.flipCamera();
```

## Flash (Off/On)
By default, flash is OFF.
```dart
await controller.toggleFlash();
```

## Resume/Pause
Pause camera stream and scanner.
```dart
await controller.pause();
```
Resume camera stream and scanner.
```dart
await controller.resume();
```

## Controller
Most controller methods return `ReturnStatus`.
Its defined as
```dart
enum ReturnStatus { Success, Failed }
```
If you want to get a bool from the returned object just use the `asBool` Method like this:
```dart
if((await controller.resume()).asBool){
...
}
```

You can also get the SystemFeatures from the controller:
- hasFlash
- hasBackCamera
- hasFrontCamera 
```dart
controller.systemFeatures.hasBackCamera
```

To get the active camera (front or back):
var backCameraIsActive = controller.activeCamera == Camera.BackCamera
var FrontCameraIsActive = controller.activeCamera == Camera.FrontCamera

## dispose
Turn off flash automatically if you call dispose
```dart
QRView(
      turnFlashOffOnDispose: true,
  ),
```



# SDK
Requires at least SDK 24 (Android 7.0).

# TODOs
* iOS Native embedding is written to match what is supported in the framework as of the date of publication of this package. It needs to be improved as the framework support improves.
* In future, options will be provided for default states.
* Finally, I welcome PR's to make it better :), thanks

# Credits
* Android: https://github.com/zxing/zxing
* iOS: https://github.com/mikebuss/MTBBarcodeScanner
* Special Thanks To: LeonDevLifeLog for his contributions towards improving this package.
