import 'dart:async';

import 'package:scheduled_notifications/scheduled_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

setearNotificaciones(SharedPreferences prefs) async {
  await cancelarNotificaciones(prefs);
  DateTime ahora = new DateTime.now();
  DateTime noche = new DateTime(ahora.year, ahora.month, ahora.day, 23);
  prefs.setInt(
      "notif1",
      await notificacion("Oraciones Santa Brígida",
          "¡Terminá las oraciones de hoy!", noche));
          // "Ya hiciste hasta la $_oracionActual oración", noche));
}

Future cancelarNotificaciones(SharedPreferences prefs) async {
  int notif1 = prefs.getInt("notif1");
  if (await ScheduledNotifications.hasScheduledNotification(notif1))
    ScheduledNotifications.unscheduleNotification(notif1);
}

Future<int> notificacion(String titulo, String contenido, DateTime cuando) {
  return ScheduledNotifications.scheduleNotification(
      cuando.millisecondsSinceEpoch, titulo, titulo, contenido);
}
