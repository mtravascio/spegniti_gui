import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(GetMaterialApp(home: ShutdownTimerScreen()));
}

class ShutdownController extends GetxController {
  Rx<int> remainingTime = 0.obs; // Tempo rimanente in secondi
  late Timer _timer;

  // Metodo per iniziare il countdown
  void startTimer(DateTime shutdownTime) {
    final currentTime = DateTime.now();
    remainingTime.value = shutdownTime.difference(currentTime).inSeconds;

    // Se il tempo è già scaduto, esegui immediatamente lo spegnimento
    if (remainingTime.value.isNegative) {
      _shutdown();
      return;
    }

    // Avvia il timer per aggiornare il countdown
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime.value > 0) {
        remainingTime.value--;
      } else {
        timer.cancel();
        _shutdown();
      }
    });
  }

  // Metodo per spegnere il sistema
  Future<void> _shutdown() async {
    // A seconda del sistema operativo, esegui il comando di spegnimento
    if (Platform.isWindows) {
      await Process.run('shutdown', ['/f', '/s', '/t', '0']).then((result) {});
    } else if (Platform.isLinux) {
      await Process.run('poweroff', []);
    } else if (Platform.isMacOS) {
      var process = await Process.start('sudo', ['-S', 'shutdown', '-h', 'now'],
          mode: ProcessStartMode.normal);
      process.stdin.writeln('password');
    }
  }

  @override
  void onClose() {
    _timer.cancel();
    super.onClose();
  }
}

class ShutdownTimerScreen extends StatelessWidget {
  final TextEditingController timeController = TextEditingController();
  final ShutdownController controller = Get.put(ShutdownController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spegniti GUI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: "Inserisci l'ora di spegnimento (HH:MM)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("Click!!!");
                final inputTime = timeController.text.trim();
                if (inputTime.isEmpty) return;

                final now = DateTime.now();
                final targetTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse(inputTime.split(":")[0]),
                    int.parse(inputTime.split(":")[1]));
                print(now.toString() + ' - ' + targetTime.toString());
                /*Get.defaultDialog(
                    middleText: targetTime.toString(),
                    title: 'ATTENZIONE!',
                    textConfirm: 'Shutdown partito!');*/
                if (targetTime.isBefore(now)) {
                  // Se l'ora inserita è già passata, impostiamo il giorno successivo
                  targetTime.add(Duration(days: 1));
                }
                controller.startTimer(targetTime);
              },
              child: Text('Avvia il Timer!'),
            ),
            SizedBox(height: 20),
            Obx(() {
              final remaining = controller.remainingTime.value;
              final hours = (remaining / 3600).floor();
              final minutes = ((remaining % 3600) / 60).floor();
              final seconds = remaining % 60;

              return Text(
                'Tempo rimanente: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 24),
              );
            }),
          ],
        ),
      ),
    );
  }
}
