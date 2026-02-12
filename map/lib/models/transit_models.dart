
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Stop {
  final int id;
  final String name;
  final LatLng position;

  Stop({required this.id, required this.name, required this.position});

  factory Stop.fromCsv(List<dynamic> row) {
    return Stop(
      id: int.parse(row[0].toString()),
      name: row[1].toString(),
      position: LatLng(double.parse(row[2].toString()), double.parse(row[3].toString())),
    );
  }
}

class TransitRoute {
  final int id;
  final String name;
  final String color;

  TransitRoute({required this.id, required this.name, required this.color});

  factory TransitRoute.fromCsv(List<dynamic> row) {
    return TransitRoute(
      id: int.parse(row[0].toString()),
      name: row[1].toString(),
      color: row[2].toString(),
    );
  }
}

class RouteStop {
  final int routeId;
  final int stopId;
  final int sequence;

  RouteStop({required this.routeId, required this.stopId, required this.sequence});

  factory RouteStop.fromCsv(List<dynamic> row) {
    return RouteStop(
      routeId: int.parse(row[0].toString()),
      stopId: int.parse(row[1].toString()),
      sequence: int.parse(row[2].toString()),
    );
  }
}

class Vehicle {
  final int id;
  final int routeId;
  final String label;

  Vehicle({required this.id, required this.routeId, required this.label});

  factory Vehicle.fromCsv(List<dynamic> row) {
    return Vehicle(
      id: int.parse(row[0].toString()),
      routeId: int.parse(row[1].toString()),
      label: row[2].toString(),
    );
  }
}

class RoutePlan {
  final String type; // 'direct' or 'transfer'
  final List<RouteLeg> legs;
  final String instruction;

  RoutePlan({required this.type, required this.legs, required this.instruction});
}

class RouteLeg {
  final TransitRoute route;
  final Stop fromStop;
  final Stop toStop;
  final List<Stop> stops; // Ordered list of stops in this leg for drawing polyline
  final List<Vehicle> vehicles;

  RouteLeg({
    required this.route,
    required this.fromStop,
    required this.toStop,
    required this.stops,
    required this.vehicles,
  });
}
