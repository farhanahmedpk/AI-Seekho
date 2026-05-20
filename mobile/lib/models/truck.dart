class Truck {
  final String truckId;
  final String driverName;
  final String cargoType;
  final double currentTemp;
  final double thresholdTemp;
  final String status;
  final String origin;
  final String destination;

  Truck({
    required this.truckId,
    required this.driverName,
    required this.cargoType,
    required this.currentTemp,
    required this.thresholdTemp,
    required this.status,
    required this.origin,
    required this.destination,
  });

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      truckId: json['truck_id'] ?? '',
      driverName: json['driver_name'] ?? '',
      cargoType: json['cargo_type'] ?? '',
      currentTemp: (json['current_temp'] ?? 0.0).toDouble(),
      thresholdTemp: (json['threshold_temp'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
    );
  }
}
