
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/transit_models.dart';
import '../services/transit_service.dart';

class TransitPlannerScreen extends StatefulWidget {
  const TransitPlannerScreen({super.key});

  @override
  State<TransitPlannerScreen> createState() => _TransitPlannerScreenState();
}

class _TransitPlannerScreenState extends State<TransitPlannerScreen> {
  final TransitService _service = TransitService();
  List<Stop> _stops = [];
  bool _isLoading = true;

  Stop? _fromStop;
  Stop? _toStop;
  List<RoutePlan> _routes = [];
  RoutePlan? _selectedRoute;

  // Map
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(27.7172, 85.3240), // Kathmandu
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.loadData();
    setState(() {
      _stops = _service.getStops();
      _isLoading = false;
    });
  }

  void _findRoutes() {
    if (_fromStop == null || _toStop == null) return;
    
    setState(() {
      _routes = _service.findRoutes(_fromStop!.id, _toStop!.id);
      _selectedRoute = null;
      _polylines.clear();
      _markers.clear();
    });

    if (_routes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No routes found with max 1 transfer.')));
    } else {
      _selectRoute(_routes.first);
    }
  }

  void _selectRoute(RoutePlan plan) {
    setState(() {
      _selectedRoute = plan;
      _updateMap(plan);
    });
  }

  void _updateMap(RoutePlan plan) {
    Set<Polyline> newPolylines = {};
    Set<Marker> newMarkers = {};
    
    LatLngBounds? bounds;

    print('DEBUG: Updating map for plan with ${plan.legs.length} legs');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rendering Route on Map...'), duration: Duration(milliseconds: 500)));

    // Add Start/End Markers
    try {
      newMarkers.add(Marker(
        markerId: const MarkerId('start'),
        position: plan.legs.first.fromStop.position,
        infoWindow: InfoWindow(title: 'Start: ${plan.legs.first.fromStop.name}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));

      newMarkers.add(Marker(
        markerId: const MarkerId('end'),
        position: plan.legs.last.toStop.position,
        infoWindow: InfoWindow(title: 'End: ${plan.legs.last.toStop.name}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    } catch (e) {
      print('DEBUG: Error adding markers: $e');
    }

    // Process Legs
    for (var leg in plan.legs) {
        // Color
        Color color = Colors.blue; 
        try {
           String hex = leg.route.color.replaceAll('#', '');
           if (hex.length == 6) {
             color = Color(int.parse('0xFF$hex'));
           }
        } catch (_) {}

        List<LatLng> points = leg.stops.map((s) => s.position).toList();
        
        newPolylines.add(Polyline(
          polylineId: PolylineId('route_${leg.route.id}_${leg.fromStop.id}'),
          points: points,
          color: color,
          width: 5,
        ));

        // Transfer Marker
        if (plan.legs.length > 1 && leg == plan.legs.first) {
             newMarkers.add(Marker(
              markerId: const MarkerId('transfer'),
              position: leg.toStop.position,
              infoWindow: InfoWindow(title: 'Transfer: ${leg.toStop.name}'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            ));
        }
        
        // Bounds calc
        for (var point in points) {
           if (bounds == null) {
             bounds = LatLngBounds(southwest: point, northeast: point);
           } else {
             bounds = LatLngBounds(
               southwest: LatLng(
                 point.latitude < bounds!.southwest.latitude ? point.latitude : bounds!.southwest.latitude,
                 point.longitude < bounds!.southwest.longitude ? point.longitude : bounds!.southwest.longitude,
               ),
               northeast: LatLng(
                 point.latitude > bounds!.northeast.latitude ? point.latitude : bounds!.northeast.latitude,
                 point.longitude > bounds!.northeast.longitude ? point.longitude : bounds!.northeast.longitude,
               ),
             );
           }
        }
    }

    setState(() {
      _polylines = newPolylines;
      _markers = newMarkers;
    });

    if (bounds != null && _mapController != null) {
      try {
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds!, 50));
      } catch (e) {
        print('Error animating camera: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transit Planner MVP')),
      body: Column(
        children: [
          // Input Selectors
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading ? const CircularProgressIndicator() : Column(
              children: [
                DropdownButton<Stop>(
                  hint: const Text('Select Start'),
                  value: _fromStop,
                  isExpanded: true,
                  items: _stops.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (s) => setState(() => _fromStop = s),
                ),
                DropdownButton<Stop>(
                  hint: const Text('Select Destination'),
                  value: _toStop,
                  isExpanded: true,
                  items: _stops.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (s) => setState(() => _toStop = s),
                ),
                ElevatedButton(
                  onPressed: _findRoutes,
                  child: const Text('Find Route'),
                ),
              ],
            ),
          ),
          
          // Route Options List
          if (_routes.isNotEmpty)
            SizedBox(
              height: 120, // Reduced height
              child: ListView.builder(
                itemCount: _routes.length,
                itemBuilder: (context, index) {
                  final plan = _routes[index];
                  final isSelected = plan == _selectedRoute;
                  return Card(
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: ListTile(
                      title: Text(plan.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(plan.instruction, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => _selectRoute(plan),
                    ),
                  );
                },
              ),
            ),
            
           // Map
           Expanded(
             child: GoogleMap(
               initialCameraPosition: _kInitialPosition,
               onMapCreated: (c) {
                 _mapController = c;
                 // If we successfully selected a route before map was ready, update camera now
                 if (_selectedRoute != null) {
                   _updateMap(_selectedRoute!);
                 }
               },
               polylines: _polylines,
               markers: _markers,
             ),
           ),
           
           // Vehicles Info Pane
           if (_selectedRoute != null)
             Container(
               color: Colors.grey.shade100,
               padding: const EdgeInsets.all(8),
               height: 100,
               child: ListView(
                 children: _selectedRoute!.legs.map((leg) {
                   return ListTile(
                     dense: true,
                     leading: const Icon(Icons.directions_bus),
                     title: Text('${leg.route.name}'),
                     subtitle: Text('Vehicles: ${leg.vehicles.map((v) => v.label).join(', ')}'),
                   );
                 }).toList(),
               ),
             ),
        ],
      ),
    );
  }
}
