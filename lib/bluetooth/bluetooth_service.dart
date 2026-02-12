import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pustimo_app/bluetooth/bluetooth_constants.dart';

class PustimoBluetoothService {
  PustimoBluetoothService._();
  static final instance = PustimoBluetoothService._();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamController<int>? _intakeController;
  int _currentIntake = 0;

  BluetoothDevice? get device => _device;
  BluetoothCharacteristic? get characteristic => _characteristic;

  /// Stream of COUNT values received from the device (e.g. "COUNT:100" → 100).
  Stream<int> get intakeStream {
    _intakeController ??= StreamController<int>.broadcast();
    return _intakeController!.stream;
  }

  /// Latest intake value received from the device.
  int get currentIntake => _currentIntake;

  /// Whether a compatible device is connected and we're receiving data.
  bool get isConnected => _device != null;

  final _scanResults = <BluetoothDevice, ScanResult>{};
  final _scanController = StreamController<List<ScanResult>>.broadcast();

  Stream<List<ScanResult>> get scanResults => _scanController.stream;

  /// Step 1: Scan only for ESP32
  Future<void> startScan() async {
    _scanResults.clear();

    await FlutterBluePlus.startScan(
      withServices: [Esp32Uuids.service],
      timeout: const Duration(seconds: 10),
    );

    FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        _scanResults[r.device] = r;
      }
      _scanController.add(_scanResults.values.toList());
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Step 2–4: Verify and connect, then subscribe to COUNT updates
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_device != null) {
      await disconnect();
    }

    await device.connect(autoConnect: false, license: License.free);

    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid == Esp32Uuids.service) {
        for (final c in service.characteristics) {
          if (c.uuid == Esp32Uuids.characteristic) {
            _device = device;
            _characteristic = c;

            // Subscribe to notifications to receive "COUNT:100" etc.
            if (c.properties.notify || c.properties.indicate) {
              await c.setNotifyValue(true);
              _characteristicSubscription = c.onValueReceived.listen(
                _handleDataReceived,
                onError: (e) => print('Characteristic error: $e'),
              );
            }

            // Clear state when device disconnects
            _connectionStateSubscription = device.connectionState.listen((state) {
              if (state == BluetoothConnectionState.disconnected) {
                _device = null;
                _characteristic = null;
                _characteristicSubscription?.cancel();
                _characteristicSubscription = null;
                _connectionStateSubscription?.cancel();
                _connectionStateSubscription = null;
              }
            });

            return true;
          }
        }
      }
    }

    await device.disconnect();
    return false;
  }

  void _handleDataReceived(List<int> data) {
    try {
      final message = utf8.decode(data).trim();
      // Parse "COUNT:100" format
      if (message.startsWith('COUNT:')) {
        final count = int.tryParse(message.substring(6).trim());
        if (count != null) {
          _currentIntake = count;
          _intakeController?.add(_currentIntake);
        }
      } else {
        final count = int.tryParse(message.trim());
        if (count != null) {
          _currentIntake = count;
          _intakeController?.add(_currentIntake);
        }
      }
    } catch (e) {
      print('Parse COUNT error: $e');
    }
  }

  /// Graceful disconnect
  Future<void> disconnect() async {
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    if (_device != null) {
      await _device!.disconnect();
      _device = null;
      _characteristic = null;
    }
  }
}
