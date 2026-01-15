class InputRecord {
  final int index;
  final double arrival;
  final double service;

  InputRecord({
    required this.index,
    required this.arrival,
    required this.service,
  });
}

class SimRecord {
  final int index;
  final double arrival;
  final double service;
  final double start;
  final double finish;
  final double wait;
  final double systemTime;

  SimRecord({
    required this.index,
    required this.arrival,
    required this.service,
    required this.start,
    required this.finish,
    required this.wait,
    required this.systemTime,
  });

  bool get waited => wait > 0;
}
