import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamController<int>? _intakeController;
  int _currentIntake = 0;
  bool _isDeviceConnected = false;

  // Standard UUID-k (módosíthatók a konkrét eszközhöz)
  // Ha az eszköz egyedi UUID-kat használ, ezeket itt kell módosítani
  // Jelenleg nem használjuk, mert automatikusan keressük a notify/indicate karakterisztikákat
  // static const String _serviceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
  // static const String _characteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  // Stream az intake értékekhez
  Stream<int> get intakeStream {
    _intakeController ??= StreamController<int>.broadcast();
    return _intakeController!.stream;
  }

  int get currentIntake => _currentIntake;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  bool get isConnected => _isDeviceConnected && _connectedDevice != null;

  /// Kapcsolódás eszközhöz és előfizetés az adatokra
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Ha már kapcsolódva van másik eszközhöz, szakítsuk meg azt
      if (_connectedDevice != null && _connectedDevice != device) {
        await disconnect();
      }

      // Ha már kapcsolódva van ugyanahhoz az eszközhöz, ne csináljunk semmit
      if (_connectedDevice == device && isConnected) {
        return;
      }

      // Kapcsolódás
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
        license: License.free,
      );

      _connectedDevice = device;
      _isDeviceConnected = true;

      // Várjuk meg, amíg a kapcsolat teljesen létrejön
      await Future.delayed(const Duration(milliseconds: 500));

      // Szolgáltatások és karakterisztikák felfedezése
      await _discoverServices(device);

      // Figyeljük a kapcsolat állapotát
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.connected) {
            _isDeviceConnected = true;
          } else if (state == BluetoothConnectionState.disconnected) {
            _isDeviceConnected = false;
            _handleDisconnection();
          }
        },
        onError: (error) {
          print('Hiba a kapcsolat állapotának figyelése során: $error');
          _isDeviceConnected = false;
          _handleDisconnection();
        },
      );
    } catch (e) {
      print('Hiba a kapcsolódás során: $e');
      rethrow;
    }
  }

  /// Szolgáltatások és karakterisztikák felfedezése
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      for (final service in services) {
        // Keresés a megfelelő karakterisztikára
        for (final characteristic in service.characteristics) {
          // Ellenőrizzük, hogy a karakterisztika értesítéseket tud-e küldeni
          if (characteristic.properties.notify ||
              characteristic.properties.indicate ||
              characteristic.properties.read) {
            // Próbáljuk meg előfizetni az értesítésekre
            try {
              if (characteristic.properties.notify ||
                  characteristic.properties.indicate) {
                await characteristic.setNotifyValue(true);
                _characteristicSubscription = characteristic.onValueReceived
                    .listen(
                      _handleDataReceived,
                      onError: (error) {
                        print('Hiba az adatok fogadása során: $error');
                      },
                    );
                print('Előfizetve karakterisztikára: ${characteristic.uuid}');
                return; // Megtaláltuk, kilépünk
              } else if (characteristic.properties.read) {
                // Ha nincs notify, periodikusan olvassuk
                _startPeriodicRead(characteristic);
                print('Periodikus olvasás beállítva: ${characteristic.uuid}');
                return; // Megtaláltuk, kilépünk
              }
            } catch (e) {
              print('Nem sikerült előfizetni: $e');
            }
          }
        }
      }

      // Ha nem találtunk megfelelő karakterisztikát a standard UUID-vel,
      // próbáljuk meg az első elérhető notify/indicate karakterisztikát
      if (_characteristicSubscription == null) {
        for (final service in services) {
          for (final characteristic in service.characteristics) {
            if (characteristic.properties.notify ||
                characteristic.properties.indicate) {
              try {
                await characteristic.setNotifyValue(true);
                _characteristicSubscription = characteristic.onValueReceived
                    .listen(
                      _handleDataReceived,
                      onError: (error) {
                        print('Hiba az adatok fogadása során: $error');
                      },
                    );
                print(
                  'Előfizetve első elérhető karakterisztikára: ${characteristic.uuid}',
                );
                break;
              } catch (e) {
                print('Nem sikerült előfizetni: $e');
              }
            }
          }
          if (_characteristicSubscription != null) break;
        }
      }
    } catch (e) {
      print('Hiba a szolgáltatások felfedezése során: $e');
      rethrow;
    }
  }

  /// Periodikus olvasás, ha nincs notify támogatás
  Timer? _periodicReadTimer;

  void _startPeriodicRead(BluetoothCharacteristic characteristic) {
    _periodicReadTimer?.cancel();
    _periodicReadTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      try {
        if (isConnected) {
          final value = await characteristic.read();
          _handleDataReceived(value);
        } else {
          timer.cancel();
        }
      } catch (e) {
        print('Hiba a periodikus olvasás során: $e');
      }
    });
  }

  /// Adatok fogadásának kezelése
  void _handleDataReceived(List<int> data) {
    try {
      // Konvertálás stringgé
      final String message = utf8.decode(data).trim();

      // Feldolgozás "COUNT:10" formátum
      if (message.startsWith('COUNT:')) {
        final countStr = message.substring(6).trim();
        final count = int.tryParse(countStr);

        if (count != null) {
          _currentIntake = count;
          _intakeController?.add(_currentIntake);
          print('Beérkezett COUNT: $_currentIntake');
        }
      } else {
        // Próbáljuk meg úgy is, ha nincs "COUNT:" prefix
        final count = int.tryParse(message.trim());
        if (count != null) {
          _currentIntake = count;
          _intakeController?.add(_currentIntake);
          print('Beérkezett érték: $_currentIntake');
        }
      }
    } catch (e) {
      print('Hiba az adatok feldolgozása során: $e');
      // Próbáljuk meg közvetlenül integerként is
      try {
        if (data.isNotEmpty) {
          // Lehet, hogy közvetlenül számként jön
          if (data.length == 1) {
            _currentIntake = data[0];
            _intakeController?.add(_currentIntake);
          } else if (data.length == 4) {
            // Big-endian int32
            _currentIntake =
                (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
            _intakeController?.add(_currentIntake);
          }
        }
      } catch (e2) {
        print('Hiba az alternatív feldolgozás során: $e2');
      }
    }
  }

  /// Kapcsolat megszakítása
  Future<void> disconnect() async {
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _periodicReadTimer?.cancel();
    _periodicReadTimer = null;
    _isDeviceConnected = false;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Hiba a kapcsolat bontásakor: $e');
      }
      _connectedDevice = null;
    }
  }

  /// Kapcsolat megszakításának kezelése
  void _handleDisconnection() {
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _periodicReadTimer?.cancel();
    _periodicReadTimer = null;
    _isDeviceConnected = false;
    // Ne nullázzuk le a _connectedDevice-et itt, mert lehet, hogy újra kapcsolódni fog
    // Csak akkor, ha explicit módon disconnect()-ot hívunk
  }

  /// Cleanup
  void dispose() {
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _periodicReadTimer?.cancel();
    _intakeController?.close();
    _intakeController = null;
    _isDeviceConnected = false;
    _connectedDevice = null;
  }
}
