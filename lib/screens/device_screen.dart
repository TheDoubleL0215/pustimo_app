import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pustimo_app/bluetooth/bluetooth_service.dart';
import 'package:toastification/toastification.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _isScanning = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _listenToAdapterState();
    _startScanning();
  }

  void _checkBluetoothState() {
    FlutterBluePlus.adapterState.first.then((state) {
      if (mounted) {
        setState(() {
          _adapterState = state;
        });
      }
    });
  }

  void _listenToAdapterState() {
    FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() {
          _adapterState = state;
        });
      }
    });
  }

  Future<void> _startScanning() async {
    if (_adapterState != BluetoothAdapterState.on) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      await PustimoBluetoothService.instance.startScan();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showError('Nem sikerült elindítani a keresést: ${e.toString()}');
      }
    }
  }

  Future<void> _stopScanning() async {
    try {
      await PustimoBluetoothService.instance.stopScan();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      _showError('Nem sikerült leállítani a keresést: ${e.toString()}');
    }
  }

  Future<void> _enableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      _showError('Nem sikerült bekapcsolni a Bluetooth-ot: ${e.toString()}');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final connectedDevice = PustimoBluetoothService.instance.device;

    // Ha már csatlakoztatva van ez az eszköz, bontjuk a kapcsolatot
    if (connectedDevice?.remoteId == device.remoteId) {
      await _disconnectFromDevice();
      return;
    }

    // Ha másik eszközhöz van kapcsolódva, először bontjuk azt
    if (connectedDevice != null) {
      await _disconnectFromDevice();
    }

    try {
      _showInfo('Kapcsolódás...');

      final success = await PustimoBluetoothService.instance.connectToDevice(
        device,
      );
      if (!mounted) return;

      if (success) {
        _showSuccess(
          'Sikeres kapcsolódás: ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}',
        );
        setState(() {}); // Frissítjük a UI-t
      } else {
        _showError(
          'Az eszköz nem kompatibilis vagy nem található a szükséges szolgáltatások.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Nem sikerült kapcsolódni: ${e.toString()}');
    }
  }

  Future<void> _disconnectFromDevice() async {
    try {
      await PustimoBluetoothService.instance.disconnect();
      if (mounted) {
        setState(() {});
        _showInfo('Kapcsolat megszakítva');
      }
    } catch (e) {
      _showError('Nem sikerült bontani a kapcsolatot: ${e.toString()}');
    }
  }

  void _showSuccess(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _showError(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _showInfo(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  String _getAdapterStateText() {
    switch (_adapterState) {
      case BluetoothAdapterState.on:
        return 'Bluetooth bekapcsolva';
      case BluetoothAdapterState.off:
        return 'Bluetooth kikapcsolva';
      case BluetoothAdapterState.turningOn:
        return 'Bluetooth bekapcsolás...';
      case BluetoothAdapterState.turningOff:
        return 'Bluetooth kikapcsolás...';
      default:
        return 'Bluetooth állapot ismeretlen';
    }
  }

  @override
  void dispose() {
    PustimoBluetoothService.instance.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = PustimoBluetoothService.instance.device;

    return Scaffold(
      appBar: AppBar(title: const Text('Eszköz csatlakoztatása'), elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            // Bluetooth állapot kártya
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _adapterState == BluetoothAdapterState.on
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: _adapterState == BluetoothAdapterState.on
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getAdapterStateText(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (connectedDevice != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Kapcsolódva: ${connectedDevice.platformName.isNotEmpty ? connectedDevice.platformName : connectedDevice.remoteId.str}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_adapterState != BluetoothAdapterState.on)
                        ElevatedButton.icon(
                          onPressed: _enableBluetooth,
                          icon: const Icon(Icons.power_settings_new, size: 18),
                          label: const Text('Bekapcsolás'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Keresés vezérlő gombok
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _adapterState == BluetoothAdapterState.on
                          ? (_isScanning ? _stopScanning : _startScanning)
                          : null,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        _isScanning ? 'Keresés...' : 'Keresés indítása',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Csatlakoztatott eszköz kártya
            if (connectedDevice != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 2,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bluetooth_connected,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Csatlakoztatott eszköz',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                connectedDevice.platformName.isNotEmpty
                                    ? connectedDevice.platformName
                                    : connectedDevice.remoteId.str,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                              Text(
                                connectedDevice.remoteId.str,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _disconnectFromDevice,
                          icon: const Icon(Icons.close),
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          tooltip: 'Kapcsolat bontása',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (connectedDevice != null) const SizedBox(height: 16),

            // Eszközlista
            Expanded(
              child: _adapterState != BluetoothAdapterState.on
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Kérjük, kapcsold be a Bluetooth-ot',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : StreamBuilder<List<ScanResult>>(
                      stream: PustimoBluetoothService.instance.scanResults,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isScanning)
                                  const CircularProgressIndicator()
                                else
                                  Icon(
                                    Icons.devices_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  _isScanning
                                      ? 'Eszközök keresése...'
                                      : 'Nincsenek talált eszközök',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                if (!_isScanning)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Nyomd meg a "Keresés indítása" gombot',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }

                        final results = snapshot.data!;
                        final connectedDeviceId = connectedDevice?.remoteId;

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final result = results[index];
                            final device = result.device;
                            final isConnected =
                                connectedDeviceId == device.remoteId;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              elevation: isConnected ? 4 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isConnected
                                    ? BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                onTap: () => _connectToDevice(device),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isConnected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          isConnected
                                              ? Icons.bluetooth_connected
                                              : Icons.bluetooth,
                                          color: isConnected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.grey[700],
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              device.platformName.isNotEmpty
                                                  ? device.platformName
                                                  : 'Ismeretlen eszköz',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              device.remoteId.str,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                if (isConnected) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Kapcsolódva',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isConnected
                                            ? Icons.check_circle
                                            : Icons.arrow_forward_ios,
                                        color: isConnected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.grey[400],
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
