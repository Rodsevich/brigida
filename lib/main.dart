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

  bool get terminoHoy =>
      (prefs != null) ? _oracionLlegada >= oraciones.length - 1 : false;

  int get oracionActual => _oracionActual;

  get diasRealizados => fechaFin.difference(fechaComienzo).inDays + 1;

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

  DateTime _horarioNotificaciones;

  DateTime get horarioNotificaciones => _horarioNotificaciones;

  void set horarioNotificaciones(DateTime horarioNotificaciones) {
    _horarioNotificaciones = horarioNotificaciones;
    prefs.setInt("horario_notificaciones",
        _horarioNotificaciones.millisecondsSinceEpoch);
  }

  DateTime _fechaComienzo;

  DateTime get fechaComienzo => _fechaComienzo;

  void set fechaComienzo(DateTime fechaComienzo) {
    _fechaComienzo = fechaComienzo;
    prefs.setInt("fecha_comienzo", fechaComienzo.millisecondsSinceEpoch);
  }

  DateTime _fechaFin;

  DateTime get fechaFin => _fechaFin;

  void set fechaFin(DateTime nuevaFechaFin) {
    if (_fechaFin.isBefore(mediaNoche.subtract(new Duration(days: 1)))) {
      _preguntarSiEmpezarDeNuevo().then((bool empezarDeNuevo) {
        manejarRespuestaEmpezarDeNuevo(empezarDeNuevo);
        if (empezarDeNuevo) _fechaFin = nuevaFechaFin;
      });
    } else if (_fechaFin.isAfter(mediaNoche.subtract(new Duration(days: 1))) &&
        _fechaFin.isBefore(alba)) {
      // if (nuevaFechaFin.isBefore(alba)) {
      _fechaFin = nuevaFechaFin;
      prefs.setInt("fecha_fin", nuevaFechaFin.millisecondsSinceEpoch);
      // }
    }
  }

  DateTime get alba => mediaNoche.add(new Duration(hours: 5));

  DateTime get mediaNoche {
    DateTime ahora = new DateTime.now();
    return new DateTime(ahora.year, ahora.month, ahora.day);
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
          print("Configurando ahora la fecha de comienzo!");
          fechaComienzo = new DateTime.now();
        }
        _fechaFin = new DateTime.fromMillisecondsSinceEpoch(
            prefs.getInt("fecha_fin") ?? 0);
        if (fechaFin.year >= 2017) {
          if (fechaFin.isAfter(mediaNoche.subtract(new Duration(days: 1))) &&
              fechaFin.isBefore(alba)) {
            if (_oracionLlegada == oraciones.length - 1) {
              oracionActual = 0;
              oracionLlegada = 0;
            }
          } else if (fechaFin
              .isBefore(mediaNoche.subtract(new Duration(days: 1))))
            _preguntarSiEmpezarDeNuevo().then(manejarRespuestaEmpezarDeNuevo);
        } else
          _fechaFin = new DateTime.now();
        print("$fechaComienzo - $fechaFin ($_oracionActual/$oracionLlegada)");
        int notif = prefs.getInt("horario_notificaciones") ??
            mediaNoche
                .add(new Duration(hours: 21, minutes: 30))
                .millisecondsSinceEpoch;
        _horarioNotificaciones = new DateTime.fromMillisecondsSinceEpoch(notif);
        _configurarNotificaciones();
      });
    });
    menu.configurar(
        onComienzoConfigurado: (DateTime dt) {
          fechaComienzo = dt;
        },
        onDiaFinalizado: _terminarDia,
        onHoraNotificaciones: (DateTime dt) {
          horarioNotificaciones = dt;
          _configurarNotificaciones();
        });
  }

  _terminarDia() {
    setState(() {
      _oracionActual = oraciones.length - 1;
      _oracionLlegada = oraciones.length - 1;
      fechaFin = new DateTime.now();
      notificaciones.cancelarNotificaciones(prefs);
    });
  }

  void _configurarNotificaciones() {
    DateTime dt = (horarioNotificaciones.isBefore(new DateTime.now()))
        ? new DateTime.now().add(new Duration(minutes: 5))
        : horarioNotificaciones;
    notificaciones.setearNotificaciones(
        prefs, dt, _oracionLlegada + 1, diasRealizados);
  }

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
      floatingActionButton: terminoHoy
          ? new FloatingActionButton(
              tooltip: 'Mostrar progreso',
              backgroundColor: Colors.orange,
              child: new Icon(_progresoMostrado ? Icons.close : Icons.info),
              onPressed: _mostrarProgreso)
          : null,
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
                      "Empezaste el ${fechaComienzo.day}/${fechaComienzo.month}/${fechaComienzo.year}\nYa hiciste $diasRealizados días de oraciones.",
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
      if (oracionActual < oraciones.length - 1) {
        if (++oracionActual > oracionLlegada) {
          oracionLlegada = oracionActual;
          _configurarNotificaciones();
        }
      } else
        _terminarDia();
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

  Future<bool> _preguntarSiEmpezarDeNuevo() {
    return showDialog<bool>(
        context: context,
        child: new AlertDialog(
            content: new Text(
              "Ayer no registré que hicieras las oraciones...",
              // style: theme.textTheme.subhead
              //     .copyWith(color: theme.textTheme.caption.color)
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Si, las hice'),
                  onPressed: () {
                    Navigator.pop(context, false);
                  }),
              new FlatButton(
                  child: const Text('No, empezar de nuevo'),
                  onPressed: () {
                    Navigator.pop(context, true);
                  })
            ]));
  }

  manejarRespuestaEmpezarDeNuevo(bool empezarDeNuevo) {
    // The value passed to Navigator.pop() or null.
    if (empezarDeNuevo == null)
      _preguntarSiEmpezarDeNuevo().then(manejarRespuestaEmpezarDeNuevo);
    else {
      setState(() {
        if (empezarDeNuevo)
          fechaComienzo = new DateTime.now();
        else
          fechaFin = mediaNoche.subtract(new Duration(seconds: 1));
      });
    }
  }
}
