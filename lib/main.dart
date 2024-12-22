import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patta Killer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FlashlightPage(),
    );
  }
}

class FlashlightPage extends StatefulWidget {
  const FlashlightPage({super.key});

  @override
  State<FlashlightPage> createState() => _FlashlightPageState();
}

class _FlashlightPageState extends State<FlashlightPage> {
  bool _isFlashlightOn = false;
  bool _hasFlashlight = false;
  bool _isLoopActive = false;
  Timer? _timer;

  final TextEditingController _onDurationController =
      TextEditingController(text: '5');
  final TextEditingController _offDurationController =
      TextEditingController(text: '5');
  final TextEditingController _totalDurationController =
      TextEditingController(text: '60');

  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _checkFlashlight();
  }

  @override
  void dispose() {
    _stopLoop();
    _onDurationController.dispose();
    _offDurationController.dispose();
    _totalDurationController.dispose();
    super.dispose();
  }

  Future<void> _checkFlashlight() async {
    bool hasFlashlight;
    try {
      hasFlashlight = await TorchLight.isTorchAvailable();
    } catch (e) {
      hasFlashlight = false;
    }
    setState(() {
      _hasFlashlight = hasFlashlight;
    });
  }

  Future<void> _toggleFlashlight(bool on) async {
    if (_isFlashlightOn == on) return;

    try {
      if (on) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
      setState(() {
        _isFlashlightOn = on;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _startLoop() {
    if (_isLoopActive) return;

    int onDuration = int.tryParse(_onDurationController.text) ?? 5;
    int offDuration = int.tryParse(_offDurationController.text) ?? 5;
    int totalDuration = int.tryParse(_totalDurationController.text) ?? 60;

    onDuration = onDuration.clamp(1, 3600);
    offDuration = offDuration.clamp(1, 3600);
    totalDuration = totalDuration.clamp(1, 7200);

    setState(() {
      _isLoopActive = true;
      _remainingSeconds = totalDuration;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopLoop();
        }
      });
    });

    _runCycle(onDuration, offDuration);
  }

  void _runCycle(int onDuration, int offDuration) {
    if (!_isLoopActive) return;

    _toggleFlashlight(true);

    _timer = Timer(Duration(seconds: onDuration), () {
      if (!_isLoopActive) return;

      _toggleFlashlight(false);

      _timer = Timer(Duration(seconds: offDuration), () {
        if (_isLoopActive) {
          _runCycle(onDuration, offDuration);
        }
      });
    });
  }

  void _stopLoop() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _toggleFlashlight(false);
    setState(() {
      _isLoopActive = false;
      _remainingSeconds = 0;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildInputField(
      String label, TextEditingController controller, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: !_isLoopActive,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffix: Text(suffix),
          border: const OutlineInputBorder(),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildActiveOverlay() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Flash: ${_isFlashlightOn ? "ON" : "OFF"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ElevatedButton(
                  onPressed: _stopLoop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                  ),
                  child: const Text(
                    'STOP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patta Killer'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInputField(
                        'Light ON Duration', _onDurationController, 'seconds'),
                    _buildInputField('Light OFF Duration',
                        _offDurationController, 'seconds'),
                    _buildInputField(
                        'Total Duration', _totalDurationController, 'seconds'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startLoop,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'START',
                style: TextStyle(fontSize: 18),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasFlashlight) {
      return const Scaffold(
        body: Center(child: Text('No flashlight available on this device')),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isLoopActive) {
          _stopLoop();
          return false;
        }
        return true;
      },
      child: _isLoopActive ? _buildActiveOverlay() : _buildSetupScreen(),
    );
  }
}
