import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_car_user_1/Providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

/// **Providers for Storing LatLng Values**
final pickupLatLngProvider = StateProvider<LatLng?>((ref) => null);
final destinationLatLngProvider = StateProvider<LatLng?>((ref) => null);

class RentalRequestPage extends ConsumerWidget {
  final String pickupLocation;
  final String destinationLocation;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String category;

  const RentalRequestPage({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupDate,
    required this.returnDate,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupLatLng = ref.watch(pickupLatLngProvider);
    final destinationLatLng = ref.watch(destinationLatLngProvider);

    /// **Convert Address to LatLng if Not Already Done**
    Future.microtask(() {
      if (pickupLatLng == null) {
        _convertAddressToLatLng(pickupLocation, ref, true);
      }
      if (destinationLatLng == null) {
        _convertAddressToLatLng(destinationLocation, ref, false);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Rental Request")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: pickupLatLng != null && destinationLatLng != null
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: pickupLatLng,
                        zoom: 12,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId("pickup"),
                          position: pickupLatLng,
                          infoWindow:
                              const InfoWindow(title: "Pickup Location"),
                        ),
                        Marker(
                          markerId: const MarkerId("destination"),
                          position: destinationLatLng,
                          infoWindow:
                              const InfoWindow(title: "Destination Location"),
                        ),
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 10),
            Text(
              "Number of Days: ${calculateDays(pickupDate, returnDate)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ref.read(sendRentalRequestProvider)(pickupLocation,
                    destinationLocation, pickupDate, returnDate, category);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Rental Request Confirmed!")),
                );
                Navigator.pop(context);
              },
              child: const Text("Confirm Request"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _cancelRentalRequest(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Cancel Request"),
            ),
          ],
        ),
      ),
    );
  }

  /// **🔹 Convert Address to LatLng**
  Future<void> _convertAddressToLatLng(
      String address, WidgetRef ref, bool isPickup) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        LatLng latLng =
            LatLng(locations.first.latitude, locations.first.longitude);
        if (isPickup) {
          ref.read(pickupLatLngProvider.notifier).state = latLng;
        } else {
          ref.read(destinationLatLngProvider.notifier).state = latLng;
        }
      }
    } catch (e) {
      print("❌ Error converting address to LatLng: $e");
    }
  }

  /// **Cancel Rental Request**
  Future<void> _cancelRentalRequest(BuildContext context) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("rental_requests")
        .where("status", isEqualTo: "pending")
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rental Request Canceled")),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active request to cancel")),
      );
    }
  }
}
