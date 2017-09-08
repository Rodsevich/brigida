import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scheduled_notifications/scheduled_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './data.dart' as data;
import './menu.dart' as menu;
import './notificaciones.dart' as notificaciones;

void main() {
  runApp(new MaterialApp(
    title: "15 Oraciones de Santa Brígida",
    theme: new ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: new OracionesWidget(),
  ));
}

class OracionesWidget extends StatefulWidget {
  OracionesWidget();

  @override
  StateOracionesWidget createState() {
    return new StateOracionesWidget();
  }
}

class StateOracionesWidget extends State<OracionesWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<String> oraciones = data.oraciones;
  List<Step> oracionesSteps = [];
  int _oracionActual;

  bool _terminoHoy;
  bool get terminoHoy => this.prefs != null ? _terminoHoy : false;

  int get oracionActual => _oracionActual;

  void set oracionActual(int oracionActual) {
    _oracionActual = oracionActual;
    prefs.setInt("oracion_actual", oracionActual);
  }

  int _oracionLlegada;

  int get oracionLlegada => _oracionLlegada;

  void set oracionLlegada(int oracionLlegada) {
    _oracionLlegada = oracionLlegada;
    prefs.setInt("oracion_llegada", oracionLlegada);
  }

  SharedPreferences prefs;

  DateTime _fechaComienzo;

  DateTime get fechaComienzo => _fechaComienzo;

  void set fechaComienzo(DateTime fechaComienzo) {
    _fechaComienzo = fechaComienzo;
    prefs.setInt("fecha_comienzo", fechaComienzo.millisecondsSinceEpoch);
  }

  DateTime _fechaFin;

  DateTime get fechaFin => _fechaFin;

  void set fechaFin(DateTime fechaFin) {
    _fechaFin = fechaFin;
    prefs.setInt("fecha_fin", fechaFin.millisecondsSinceEpoch);
    DateTime ahora = new DateTime.now();
    DateTime mediaNoche = new DateTime(ahora.year, ahora.month, ahora.day);
    DateTime manana = new DateTime(ahora.year, ahora.month, ahora.day, 5);
    if (fechaFin.isAfter(mediaNoche)) {
      if (fechaFin.isBefore(manana)) {
        fechaComienzo = new DateTime.now();
      }
    }
    _terminoHoy = true;
  }

  StateOracionesWidget() {
    SharedPreferences.getInstance().then((pref) {
      setState(() {
        this.prefs = pref;
        _oracionActual = prefs.getInt("oracion_actual") ?? 0;
        _oracionLlegada = prefs.getInt("oracion_llegada") ?? 0;
        _fechaComienzo = new DateTime.fromMillisecondsSinceEpoch(
            prefs.getInt("fecha_comienzo") ?? 0);
        if (fechaComienzo.year < 2017) {
          fechaComienzo = new DateTime.now();
        }
        _fechaFin = new DateTime.fromMillisecondsSinceEpoch(
            prefs.getInt("fecha_fin") ?? 0);
        DateTime ahora = new DateTime.now();
        DateTime mediaNoche = new DateTime(ahora.year, ahora.month, ahora.day);
        DateTime manana = new DateTime(ahora.year, ahora.month, ahora.day, 5);
        if (fechaFin.isBefore(mediaNoche)) {
          oracionActual = 0;
          oracionLlegada = 0;
        } else if (fechaFin.isAfter(manana)) {
          oracionActual = 0;
          oracionLlegada = 0;
          fechaComienzo = new DateTime.now();
        }
        _terminoHoy = fechaFin.isBefore(manana.add(new Duration(days: 1)));
      });
    });
    menu.configurar(
        onComienzoConfigurado: (DateTime dt) {
          fechaComienzo = dt;
        },
        onDiaFinalizado: _terminarDia,
        onHoraNotificaciones: (DateTime dt) {
          _configurarNotificaciones(dt);
        });
  }

  _terminarDia() {
    setState(() {
      _oracionActual = oraciones.length - 1;
      _oracionLlegada = oraciones.length - 1;
      fechaFin = new DateTime.now();
    });
  }

  void _configurarNotificaciones(DateTime dt) {}

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (this.prefs == null)
      body = const Center(
        child: const CupertinoActivityIndicator(),
      );
    else {
      _procesarOraciones();
      body = new Stepper(
        key: new Key("stepper"),
        steps: oracionesSteps,
        currentStep:
            (oracionActual < oracionesSteps.length) ? oracionActual : 0,
        // type: StepperType.horizontal,
        onStepTapped: _oracionTapeada,
        onStepContinue: _oracionContinuada,
        onStepCancel: _oracionCancelada,
      );
    }
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text("15 Oraciones de Santa Brígida"),
        actions: <Widget>[
          new PopupMenuButton<String>(
            onSelected: menu.manejarEleccionMenu,
            itemBuilder: (BuildContext context) => menu.construir(context),
          ),
        ],
      ),
      body: body,
      primary: true,
      floatingActionButton: !terminoHoy
          ? null
          : new FloatingActionButton(
              tooltip: 'Mostrar progreso',
              backgroundColor: Colors.orange,
              child: new Icon(_progresoMostrado ? Icons.close : Icons.info),
              onPressed: _mostrarProgreso),
    );
  }

  bool _progresoMostrado = false;
  PersistentBottomSheetController _controller;
  _mostrarProgreso() {
    setState(() {
      if (_progresoMostrado) {
        _controller.close();
        _progresoMostrado = false;
      } else {
        _progresoMostrado = true;
        _controller = _scaffoldKey.currentState
            .showBottomSheet<Null>((BuildContext context) {
          return new Container(
              decoration: new BoxDecoration(
                  border: new Border(
                      top: new BorderSide(
                          color: Theme.of(context).dividerColor))),
              child: new Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: new Text(
                      "Ya hiciste ${fechaFin.difference(fechaComienzo).inDays + 1} días de oraciones.",
                      style: Theme.of(context).textTheme.subhead)));
        });
        _controller.closed.then((_) {
          setState(() {
            _progresoMostrado = false;
          });
        });
      }
    });
  }

  void _oracionTapeada(int value) {
    if (value <= oracionLlegada)
      setState(() {
        oracionActual = value;
      });
  }

  void _oracionContinuada() {
    setState(() {
      if (oracionActual < oraciones.length) {
        if (++oracionActual > oracionLlegada) {
          oracionLlegada = oracionActual;
          notificaciones.setearNotificaciones(prefs);
        }
      } else {
        notificaciones.cancelarNotificaciones(prefs);
        fechaFin = new DateTime.now();
      }
    });
  }

  void _oracionCancelada() {
    setState(() {
      oracionLlegada = (oracionActual > 0) ? --oracionActual : oracionActual;
    });
  }

  void _procesarEstado() {
    _procesarOraciones();
  }

  void _procesarOraciones() {
    bool arreglar;
    for (int i = 0; i < oraciones.length; i++) {
      arreglar = false;
      try {
        if (oracionesSteps[i] == null) arreglar = true;
      } on RangeError catch (e) {
        arreglar = true;
      }
      if (!arreglar) {
        if (i <= oracionLlegada) {
          if (oracionesSteps[i].isActive == false)
            arreglar = true;
          else if (oracionesSteps[i].state != StepState.complete)
            arreglar = true;
          else if (i == oracionActual &&
              oracionesSteps[i].state != StepState.indexed) arreglar = true;
        } else {
          if (oracionesSteps[i].isActive == true)
            arreglar = true;
          else if (oracionesSteps[i].state != StepState.disabled)
            arreglar = true;
        }
      }
      if (arreglar) {
        var elem = new Step(
            title: new Text("${i + 1}ª oración",
                style: Theme.of(context).textTheme.title),
            content: new Text(oraciones[i]),
            isActive: i <= oracionLlegada,
            state: (i == oracionActual)
                ? StepState.indexed
                : (i < oracionLlegada)
                    ? StepState.complete
                    : StepState.disabled);
        try {
          oracionesSteps[i] = elem;
        } on RangeError catch (e) {
          oracionesSteps.add(elem);
        }
      }
    }
  }
}
