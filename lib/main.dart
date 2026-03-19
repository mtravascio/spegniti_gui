import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:desktop_window/desktop_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopWindow.setWindowSize(const Size(400, 560));
  runApp(const SpegnitiApp());
}

class SpegnitiApp extends StatelessWidget {
  const SpegnitiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Spegniti!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ShutdownTimerScreen(),
    );
  }
}

class ShutdownController extends GetxController {
  final RxInt remainingSeconds = 0.obs;
  final RxBool isRunning = false.obs;
  final RxBool isShuttingDown = false.obs;
  final Rx<TimeOfDay> targetTime = const TimeOfDay(hour: 0, minute: 0).obs;
  final RxString inputError = ''.obs;

  Timer? _timer;
  DateTime? _targetDateTime;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void setTargetTime(TimeOfDay time) {
    _timer?.cancel();
    isRunning.value = false;

    final now = DateTime.now();
    _targetDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (_targetDateTime!.isBefore(now)) {
      _targetDateTime = _targetDateTime!.add(const Duration(days: 1));
    }

    targetTime.value = time;
    remainingSeconds.value = _targetDateTime!.difference(now).inSeconds;
    inputError.value = '';
  }

  void setTimeFromString(String input) {
    inputError.value = '';

    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      inputError.value = 'Inserisci un orario';
      return;
    }

    final parts = trimmed.split(':');
    if (parts.length != 2) {
      inputError.value = 'Formato non valido (HH:MM)';
      return;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      inputError.value = 'Numeri non validi';
      return;
    }

    if (hour < 0 || hour > 23) {
      inputError.value = 'Ore: 0-23';
      return;
    }

    if (minute < 0 || minute > 59) {
      inputError.value = 'Minuti: 0-59';
      return;
    }

    setTargetTime(TimeOfDay(hour: hour, minute: minute));
  }

  void toggleTimer() {
    if (isRunning.value) {
      stopTimer();
    } else {
      startTimer();
    }
  }

  void startTimer() {
    if (remainingSeconds.value <= 0) {
      inputError.value = 'Imposta un orario valido';
      return;
    }

    isRunning.value = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _executeShutdown();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    isRunning.value = false;
  }

  void resetTimer() {
    stopTimer();
    remainingSeconds.value = 0;
    targetTime.value = const TimeOfDay(hour: 0, minute: 0);
    inputError.value = '';
  }

  void _executeShutdown() async {
    stopTimer();
    isShuttingDown.value = true;

    if (kIsWeb) return;

    try {
      if (Platform.isLinux) {
        await Process.run('poweroff', []);
      } else if (Platform.isWindows) {
        await Process.run('shutdown', ['/f', '/s', '/t', '0']);
      } else if (Platform.isMacOS) {
        var process = await Process.start(
          'sudo',
          ['-S', 'shutdown', '-h', 'now'],
          mode: ProcessStartMode.normal,
        );
        process.stdin.writeln('password');
      }
    } catch (e) {
      debugPrint('Shutdown error: $e');
      isShuttingDown.value = false;
    }
  }

  String get formattedRemaining {
    if (remainingSeconds.value < 0) return '--:--:--';
    final h = (remainingSeconds.value ~/ 3600).toString().padLeft(2, '0');
    final m =
        ((remainingSeconds.value % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds.value % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class ShutdownTimerScreen extends StatefulWidget {
  const ShutdownTimerScreen({super.key});

  @override
  State<ShutdownTimerScreen> createState() => _ShutdownTimerScreenState();
}

class _ShutdownTimerScreenState extends State<ShutdownTimerScreen> {
  final ShutdownController controller = Get.put(ShutdownController());
  final TextEditingController timeInputController = TextEditingController();

  @override
  void dispose() {
    timeInputController.dispose();
    super.dispose();
  }

  void _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: controller.targetTime.value,
    );

    if (picked != null && mounted) {
      controller.setTargetTime(picked);
      timeInputController.text = picked.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spegniti!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeDisplay(),
            const SizedBox(height: 16),
            _buildTimeInput(),
            const SizedBox(height: 16),
            _buildTimePickerButton(),
            const SizedBox(height: 16),
            _buildControlButtons(),
            const SizedBox(height: 16),
            _buildCountdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return Obx(() {
      final target = controller.targetTime.value;
      final formatted = target.hour == 0 && target.minute == 0
          ? '--:--'
          : target.format(context);
      return Column(
        children: [
          Icon(Icons.access_time, size: 36, color: Colors.blue),
          const SizedBox(height: 4),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTimeInput() {
    return Obx(() {
      timeInputController.text = controller.targetTime.value.hour == 0 &&
              controller.targetTime.value.minute == 0
          ? ''
          : controller.targetTime.value.format(context);

      return TextField(
        controller: timeInputController,
        decoration: InputDecoration(
          labelText: 'Orario (HH:MM)',
          hintText: '23:59',
          errorText: controller.inputError.value.isEmpty
              ? null
              : controller.inputError.value,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.timer),
        ),
        keyboardType: TextInputType.datetime,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18),
        onSubmitted: (value) {
          controller.setTimeFromString(value);
          if (controller.inputError.value.isEmpty) {
            timeInputController.text =
                controller.targetTime.value.format(context);
          }
        },
      );
    });
  }

  Widget _buildTimePickerButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showTimePicker,
        icon: const Icon(Icons.schedule),
        label: const Text('Scegli Orario'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Obx(() {
      if (controller.isShuttingDown.value) {
        return const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Spegnimento in corso...',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: controller.remainingSeconds.value > 0
                  ? controller.toggleTimer
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor:
                    controller.isRunning.value ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                controller.isRunning.value ? 'Ferma' : 'Avvia',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: controller.resetTimer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Reset'),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCountdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Obx(() {
        final seconds = controller.remainingSeconds.value;
        Color textColor = Colors.black;
        if (controller.isRunning.value && seconds <= 60 && seconds > 0) {
          textColor = Colors.orange;
        } else if (controller.isRunning.value && seconds <= 10) {
          textColor = Colors.red;
        }

        return Column(
          children: [
            const Text(
              'Countdown',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              controller.formattedRemaining,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: textColor,
              ),
            ),
            if (controller.isRunning.value) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      value: seconds > 0
                          ? seconds /
                              (controller.targetTime.value.hour * 3600 +
                                  controller.targetTime.value.minute * 60)
                          : 0,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    seconds > 0 ? 'In funzione' : 'Completato!',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}
