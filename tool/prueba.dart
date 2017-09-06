main() {
  DateTime ahora = new DateTime.now();
  DateTime mediaNoche = new DateTime(ahora.year, ahora.month, ahora.day);
  DateTime manana = new DateTime(ahora.year, ahora.month, ahora.day, 5);
  DateTime fechaComienzo = new DateTime(2016, 9, 10);
  DateTime fechaFin = new DateTime(2017, 9, 4);
  print(ahora.difference(fechaComienzo));
  print(ahora.difference(fechaComienzo).inDays);
  print(fechaComienzo.year < 2017);
  print(manana.difference(ahora));
  print(mediaNoche.difference(ahora));
  print(ahora.millisecondsSinceEpoch);
}
