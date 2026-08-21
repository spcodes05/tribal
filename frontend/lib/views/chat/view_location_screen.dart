import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';

class ViewLocationArgs {
  final double latitude;
  final double longitude;

  const ViewLocationArgs({required this.latitude, required this.longitude});
}

class ViewLocationScreen extends StatelessWidget {
  final ViewLocationArgs args;

  const ViewLocationScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(args.latitude, args.longitude);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tribal.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: point,
                  width: 30,
                  height: 30,
                  child: const Icon(Icons.location_pin,
                      color: AppColors.primary, size: 30),
                ),
              ]),
            ],
          ),
          Positioned(
            top: topPad + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}