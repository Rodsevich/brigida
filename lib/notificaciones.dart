import 'dart:async';

import 'package:scheduled_notifications/scheduled_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Definí las notificaciones para sonar cada 30 minutos a partir de lo indicado
setearNotificaciones(SharedPreferences prefs, DateTime dt, int cantidadLlegadas,
    int diasHechos) async {
  int minsAvance = 30;
  await cancelarNotificaciones(prefs);
  int notif1int = await notificacion(
      "Oraciones de Santa Brígida", "¡Terminá las oraciones de hoy!", dt);
  prefs.setInt("notif1", notif1int);
  int notif2int = await notificacion(
      "Las 15 Oraciones de Santa Brígida",
      "¡Dale que ya hiciste $cantidadLlegadas hoy!",
      dt.add(new Duration(minutes: minsAvance)));
  prefs.setInt("notif2", notif2int);
  int notif3int = await notificacion(
      "ORACIONES DE SANTA BRÍGIDA",
      "¡ESTÁS X PERDER $diasHechos DÍAS HECHOS!",
      dt.add(new Duration(minutes: minsAvance * 2)));
  prefs.setInt("notif3", notif3int);
  // "Ya hiciste hasta la $_oracionActual oración", noche));
}

Future cancelarNotificaciones(SharedPreferences prefs) async {
  for (var i = 1; i <= 3; i++) {
    int notif = prefs.getInt("notif$i") ?? 0;
    if (await ScheduledNotifications.hasScheduledNotification(notif))
      ScheduledNotifications.unscheduleNotification(notif);
  }
  return;
}

Future<int> notificacion(String titulo, String contenido, DateTime cuando) {
  return ScheduledNotifications.scheduleNotification(
      cuando.millisecondsSinceEpoch, titulo, titulo, contenido);
}
