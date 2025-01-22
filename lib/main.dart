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
  Rx<bool> timerStarted = false.obs;
  Rx<TimeOfDay> targetTime = TimeOfDay(hour: 00, minute: 00).obs;
/*
  void setTimer(DateTime shutdownTime) {
    final currentTime = DateTime.now();
    remainingTime.value = shutdownTime.difference(currentTime).inSeconds;
    debugPrint(remainingTime.value.toString());
  }
*/
  void setTimer(TimeOfDay shutdownTime) {
    targetTime.value = shutdownTime;
    final currentDateTime = DateTime.now();
    DateTime targetDateTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        shutdownTime.hour,
        shutdownTime.minute);
    debugPrint('$currentDateTime - $targetDateTime');
    if (targetDateTime.isBefore(currentDateTime)) {
      // Se l'ora inserita è già passata, impostiamo il giorno successivo
      targetDateTime = targetDateTime.add(Duration(days: 1));
      debugPrint('is before!');
    }
    remainingTime.value = targetDateTime.difference(currentDateTime).inSeconds;
    debugPrint(remainingTime.value.toString());
  }

  // Metodo per iniziare il countdown
  void startTimer() {
    if (timerStarted.value) {
      timerStarted.value = false;
    } else {
      timerStarted.value = true;
    }

    // Se il tempo è già scaduto, esegui immediatamente lo spegnimento
    if (remainingTime.value.isNegative) {
      //  _shutdown();
      debugPrint('shutdown!');
      return;
    }

    // Avvia il timer per aggiornare il countdown
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timerStarted.value && remainingTime.value > 0) {
        remainingTime.value--;
      } else if (!timerStarted.value) {
        timer.cancel();
        debugPrint('timer cancelled!');
      } else {
        timer.cancel();
        // _shutdown();
        debugPrint('shutdown!');
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
        title: Text(style: TextStyle(color: Colors.white), 'Spegniti! APP'),
        backgroundColor: Colors.blue,
        leading: const Icon(Icons.access_alarm_rounded),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  final DateTime now = DateTime.now();
                  showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay(hour: now.hour, minute: now.minute))
                      .then((TimeOfDay? value) {
                    if (value != null) {
                      /*ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(value.format(context)),
                        //action: SnackBarAction(label: 'OK', onPressed: () {}),
                      ));*/
                      //debugPrint(value.format(context));
                      controller.setTimer(value);
                    }
                  });
                },
                child: const Text("Set Time!")),
            SizedBox(height: 20),
            Obx(() {
              timeController.text =
                  controller.targetTime.value.format(context).toString();
              return TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                      labelText: '(HH:MM)',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.access_alarms)),
                  keyboardType: TextInputType.datetime,
                  onSubmitted: (value) {
                    final inputTime = value.trim();
                    if (inputTime.isNotEmpty) {
                      TimeOfDay targetTime = TimeOfDay(
                          hour: int.parse(inputTime.split(":")[0]),
                          minute: int.parse(inputTime.split(":")[1]));
                      controller.setTimer(targetTime);
                    }
                  });
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                controller.startTimer();
              },
              child: Obx(() {
                if (!controller.timerStarted.value) {
                  return Text('Start Timer!');
                } else {
                  return Text('Stop Timer!');
                }
              }),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                //controller._shutdown();
                debugPrint('shutdown!');
              },
              child: Text('Now!'),
            ),
            SizedBox(height: 20),
            Obx(() {
              final remaining = controller.remainingTime.value;
              final hours = (remaining / 3600).floor();
              final minutes = ((remaining % 3600) / 60).floor();
              final seconds = remaining % 60;

              return Text(
                'Countdown: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 24),
              );
            }),
          ],
        ),
      ),
    );
  }
}
