import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

enum MenuItems {
  CONFIGURAR_COMIENZO,
  FINALIZAR_DIA,
  CONFIGURAR_HORARIO_NOTIFICACIONES
}

List<PopupMenuItem<String>> _cache;
Function _comienzo;
Function _finDia;
Function _horaNotificaciones;
BuildContext _context;
bool _configurado = false;

void configurar(
    {@required Function onComienzoConfigurado,
    @required Function onDiaFinalizado,
    @required Function onHoraNotificaciones}) {
  _configurado = true;
  _comienzo = onComienzoConfigurado;
  _finDia = onDiaFinalizado;
  _horaNotificaciones = onHoraNotificaciones;
}

manejarEleccionMenu(String value) {
  _checkearConfigurado();
  int val = int.parse(value);
  if (val == MenuItems.CONFIGURAR_COMIENZO.index) {
    DateTime ahora = new DateTime.now();
    DateTime anioPasado = ahora.subtract(new Duration(days: 365));
    DateTime mesPasado = ahora.subtract(new Duration(days: 30));
    showDatePicker(
            context: _context,
            lastDate: ahora,
            firstDate: anioPasado,
            initialDate: mesPasado)
        .then(_comienzo);
  } else if (val == MenuItems.CONFIGURAR_HORARIO_NOTIFICACIONES.index) {
    DateTime ahora = new DateTime.now();
    showTimePicker(
            context: _context, initialTime: new TimeOfDay(hour: 21, minute: 30))
        .then((TimeOfDay time) {
      if (time != null)
        Function.apply(_horaNotificaciones, [
          new DateTime(
              ahora.year, ahora.month, ahora.day, time.hour, time.minute)
        ]);
    });
  } else if (val == MenuItems.FINALIZAR_DIA.index) {
    Function.apply(_finDia, []);
  }
}

void _checkearConfigurado() {
  if (!_configurado)
    throw new Exception(
        "Tenés que ejecutar menu.configurar() para usar el menú");
}

List<PopupMenuItem<String>> construir(BuildContext context) {
  _context = context;
  if (_cache == null) {
    List<PopupMenuItem<String>> ret = [];
    MenuItems.values.forEach((item) {
      String nombre =
          item.toString().substring(item.toString().indexOf('.') + 1);
      ret.add(new PopupMenuItem<String>(
          value: "${item.index}",
          child: new Text(nombre.replaceAll("_", " ").toLowerCase())));
    });
    _cache = ret;
    return ret;
  } else
    return _cache;
  // return [
  //   const PopupMenuItem<String>(value: '', child: const Text('Toolbar menu')),
  //   const PopupMenuItem<String>(
  //       value: 'Right here', child: const Text('Right here')),
  //   const PopupMenuItem<String>(value: 'Hooray!', child: const Text('Hooray!')),
  // ];
}
