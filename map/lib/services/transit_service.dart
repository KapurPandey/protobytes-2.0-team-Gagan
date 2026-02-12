
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import '../models/transit_models.dart';

class TransitService {
  List<Stop> _stops = [];
  List<TransitRoute> _routes = [];
  List<RouteStop> _routeStops = [];
  List<Vehicle> _vehicles = [];

  bool _isLoaded = false;

  Future<void> loadData() async {
    if (_isLoaded) return;

    _stops = await _loadCsv('assets/data/stops.csv', Stop.fromCsv);
    _routes = await _loadCsv('assets/data/routes.csv', TransitRoute.fromCsv);
    _routeStops = await _loadCsv('assets/data/route_stops.csv', RouteStop.fromCsv);
    _vehicles = await _loadCsv('assets/data/vehicles.csv', Vehicle.fromCsv);

    _isLoaded = true;
  }

  Future<List<T>> _loadCsv<T>(String path, T Function(List<dynamic>) factory) async {
    final String data = await rootBundle.loadString(path);
    final List<String> lines = data.split('\n');
    final List<T> result = [];

    // Skip header
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.isNotEmpty) {
        try {
           result.add(factory(parts));
        } catch (e) {
          print('Error parsing line $i in $path: $line. Error: $e');
        }
      }
    }
    return result;
  }

  List<Stop> getStops() => _stops;

  List<RoutePlan> findRoutes(int fromStopId, int toStopId) {
    List<RoutePlan> plans = [];

    // 1. Direct Routes
    final directRoutes = _findDirectRoutes(fromStopId, toStopId);
    plans.addAll(directRoutes);

    // 2. Transfer Routes (Max 1 transfer)
    final transferRoutes = _findTransferRoutes(fromStopId, toStopId);
    plans.addAll(transferRoutes);

    return plans;
  }

  List<RoutePlan> _findDirectRoutes(int fromId, int toId) {
    List<RoutePlan> plans = [];
    
    // Find routes containing both stops
    final fromRouteStops = _routeStops.where((rs) => rs.stopId == fromId).toList();
    final toRouteStops = _routeStops.where((rs) => rs.stopId == toId).toList();

    for (var startRs in fromRouteStops) {
      for (var endRs in toRouteStops) {
        if (startRs.routeId == endRs.routeId) {
          // Check direction: sequence must increase
          if (startRs.sequence < endRs.sequence) {
             final route = _routes.firstWhere((r) => r.id == startRs.routeId);
             final leg = _createLeg(route, startRs, endRs);
             
             plans.add(RoutePlan(
               type: 'direct', 
               legs: [leg], 
               instruction: 'Go to ${leg.fromStop.name}. Board ${route.name}. Get off at ${leg.toStop.name}.'
             ));
          }
        }
      }
    }
    return plans;
  }

  List<RoutePlan> _findTransferRoutes(int fromId, int toId) {
    List<RoutePlan> plans = [];
    
    // R1: Start -> T
    // R2: T -> End
    
    final startRouteStops = _routeStops.where((rs) => rs.stopId == fromId).toList();
    final endRouteStops = _routeStops.where((rs) => rs.stopId == toId).toList();

    for (var startRs in startRouteStops) {
       // Potential Transfer Stops on this route (after start)
       final possibleStopsOnRoute1 = _routeStops.where((rs) => rs.routeId == startRs.routeId && rs.sequence > startRs.sequence).toList();
       
       for (var transferRs1 in possibleStopsOnRoute1) {
           // Can we go from Transfer Node to End?
           // Find RouteStops for Transfer Node on OTHER routes
           final transferStopsOnOtherRoutes = _routeStops.where((rs) => rs.stopId == transferRs1.stopId && rs.routeId != startRs.routeId).toList();
           
           for (var transferRs2 in transferStopsOnOtherRoutes) {
              // Now check if this route goes to End
              final endRsMatches = endRouteStops.where((rs) => rs.routeId == transferRs2.routeId && rs.sequence > transferRs2.sequence).toList();
              
              for (var endRs in endRsMatches) {
                 // Found a valid transfer!
                 final r1 = _routes.firstWhere((r) => r.id == startRs.routeId);
                 final r2 = _routes.firstWhere((r) => r.id == transferRs2.routeId);
                 
                 final leg1 = _createLeg(r1, startRs, transferRs1);
                 final leg2 = _createLeg(r2, transferRs2, endRs);
                 
                 final transferStop = _stops.firstWhere((s) => s.id == transferRs1.stopId);

                 plans.add(RoutePlan(
                   type: 'transfer',
                   legs: [leg1, leg2],
                   instruction: 'Take ${r1.name} from ${leg1.fromStop.name} to ${transferStop.name}. Transfer to ${r2.name} and go to ${leg2.toStop.name}.'
                 ));
              }
           }
       }
    }
    
    // Deduplicate or limit? For now just return valid ones
    return plans;
  }

  RouteLeg _createLeg(TransitRoute route, RouteStop start, RouteStop end) {
     final fromStop = _stops.firstWhere((s) => s.id == start.stopId);
     final toStop = _stops.firstWhere((s) => s.id == end.stopId);
     
     // Get all stops in between for polyline
     final segmentStops = _routeStops.where((rs) => rs.routeId == route.id && rs.sequence >= start.sequence && rs.sequence <= end.sequence)
         .map((rs) => _stops.firstWhere((s) => s.id == rs.stopId))
         .toList();
         
     // Sort by sequence to be safe, though filtered list order depends on source.
     // Better to re-sort based on sequence if needed, but assuming CSV/List is robust enough for this MVP.
     // To be strictly correct let's map sequence and sort.
     
     final rawSegment = _routeStops.where((rs) => rs.routeId == route.id && rs.sequence >= start.sequence && rs.sequence <= end.sequence).toList();
     rawSegment.sort((a, b) => a.sequence.compareTo(b.sequence));
     final orderedStops = rawSegment.map((rs) => _stops.firstWhere((s) => s.id == rs.stopId)).toList();

     final vehicles = _vehicles.where((v) => v.routeId == route.id).toList();

     return RouteLeg(
       route: route,
       fromStop: fromStop,
       toStop: toStop,
       stops: orderedStops,
       vehicles: vehicles,
     );
  }
}
