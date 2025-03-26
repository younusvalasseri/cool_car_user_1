import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_car_user_1/Main/login_page.dart';
import 'package:cool_car_user_1/Providers/providers.dart';
import 'package:cool_car_user_1/Views/ride_approval_page.dart';
import 'package:cool_car_user_1/Widgets/page_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'rental_request_page.dart';

final pickupLocationProvider = StateProvider<String?>((ref) => null);
final destinationLocationProvider = StateProvider<String?>((ref) => null);
final automatePickupProvider = StateProvider<bool>((ref) => false);
final pickupDateProvider = StateProvider<DateTime?>((ref) => null);
final returnDateProvider = StateProvider<DateTime?>((ref) => null);
final returnDateErrorProvider = StateProvider<String?>((ref) => null);
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final pickupLocationControllerProvider = StateProvider<TextEditingController>(
  (ref) => TextEditingController(),
);
final destinationLocationControllerProvider =
    StateProvider<TextEditingController>(
  (ref) => TextEditingController(),
);

final placesApi = FlutterGooglePlacesSdk('YOUR_GOOGLE_PLACES_API_KEY');
final placesSuggestionsProvider =
    StateProvider<List<AutocompletePrediction>>((ref) => []);

class HomePage extends ConsumerWidget {
  HomePage({super.key});
  final user = FirebaseAuth.instance.currentUser;

  Future<void> signout(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupLocation = ref.watch(pickupLocationProvider);
    final destinationLocation = ref.watch(destinationLocationProvider);
    final pickupDate = ref.watch(pickupDateProvider);
    final returnDate = ref.watch(returnDateProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final carListState = ref.watch(carDetailsProvider);
    final automatePickup = ref.watch(automatePickupProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (pickupLocation == null ||
              destinationLocation == null ||
              pickupDate == null ||
              returnDate == null ||
              selectedCategory == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Please fill all required fields!"),
                  backgroundColor: Colors.red),
            );
            return;
          }

          if (returnDate.isBefore(pickupDate)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Return date cannot be before Pickup date!"),
                  backgroundColor: Colors.red),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RentalRequestPage(
                pickupLocation: pickupLocation,
                destinationLocation: destinationLocation,
                pickupDate: pickupDate,
                returnDate: returnDate,
                category: selectedCategory,
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.directions_car, color: Colors.white),
      ),
      appBar: AppBar(
        title: Text(user?.displayName ?? user?.email ?? 'CoolCar User'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rental_history')
                .where('userId', isEqualTo: user?.uid)
                .where('status', isEqualTo: 'Ready for Ride')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return IconButton(
                  icon:
                      const Icon(Icons.notifications_active, color: Colors.red),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RideApprovalPage()),
                    );
                  },
                );
              }
              return const SizedBox.shrink(); // Hide if no notifications
            },
          ),
          TextButton(
            onPressed: () => signout(context),
            child: const Text("Sign Out", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              PageColor.gradient(direction: GradientDirection.topToBottom),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Image.asset('assets/car.png', height: 100)),
                const SizedBox(height: 10),
                _buildLabeledField(
                    "Where to", destinationLocationProvider, ref),
                _buildLabeledField(
                    "Pick Up Location", pickupLocationProvider, ref),

                CheckboxListTile(
                  value: automatePickup,
                  onChanged: (value) async {
                    ref.read(automatePickupProvider.notifier).state =
                        value ?? false;

                    if (value == true) {
                      Position position = await _getCurrentLocation();
                      String currentLocation =
                          "${position.latitude}, ${position.longitude}";
                      ref.read(pickupLocationProvider.notifier).state =
                          currentLocation;
                      ref.read(pickupLocationControllerProvider).text =
                          currentLocation;
                    }
                  },
                  title: const Text("Automate Pickup Location"),
                ),
                const SizedBox(height: 10),

                _buildDatePicker(context, "Pickup Date", pickupDate,
                    pickupDateProvider, ref),
                _buildDatePicker(context, "Return Date", returnDate,
                    returnDateProvider, ref),

                // 🛑 Show return date validation error if it exists
                Consumer(
                  builder: (context, ref, child) {
                    final errorMessage = ref.watch(returnDateErrorProvider);
                    return errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),

                // 🚗 Car Category Selection
                const SizedBox(height: 20),
                _buildCarSelection(ref, carListState, selectedCategory),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime? date,
      StateProvider<DateTime?> provider, WidgetRef ref) {
    return ListTile(
      title: Text(
        "$label: ${date != null ? "${date.toLocal()}".split(' ')[0] : 'Select'}",
        style: TextStyle(
          color: date == null ? Colors.red : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );

        if (selectedDate != null) {
          ref.read(provider.notifier).state = selectedDate;
          if (provider == returnDateProvider) {
            DateTime? pickupDate = ref.read(pickupDateProvider);

            if (pickupDate != null && selectedDate.isBefore(pickupDate)) {
              ref.read(returnDateErrorProvider.notifier).state =
                  "Return date cannot be before Pickup date!";
            } else {
              ref.read(returnDateErrorProvider.notifier).state = null;
            }
          }
        }
      },
    );
  }

  Widget _buildLabeledField(
      String label, StateProvider<String?> provider, WidgetRef ref) {
    final value = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: value == null ? Colors.redAccent : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black, // Black shade
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: _buildPlacesAutocompleteField(ref, label, provider),
        ),
      ],
    );
  }

  Widget _buildPlacesAutocompleteField(
      WidgetRef ref, String hint, StateProvider<String?> provider) {
    return Consumer(
      builder: (context, ref, _) {
        final controller = ref.watch(provider == pickupLocationProvider
            ? pickupLocationControllerProvider
            : destinationLocationControllerProvider);

        return TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white), // White text for input
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.white70, // Light grey for visibility
              fontSize: 16,
            ),
            suffixIcon: const Icon(Icons.search, color: Colors.white),
            filled: true,
            fillColor: Colors.grey[900], // Dark Grey input field
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) async {
            if (value.isEmpty) {
              ref.read(placesSuggestionsProvider.notifier).state = [];
              ref.read(provider.notifier).state = null;
              return;
            }

            ref.read(provider.notifier).state = value;
            final result = await placesApi.findAutocompletePredictions(value);
            ref.read(placesSuggestionsProvider.notifier).state =
                result.predictions;
          },
        );
      },
    );
  }

  Widget _buildCarSelection(WidgetRef ref,
      AsyncValue<QuerySnapshot> carListState, String? selectedCategory) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Dark grey background
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Car Category:",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          carListState.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white)),
            error: (error, stackTrace) => Text("Error: $error",
                style: const TextStyle(color: Colors.white)),
            data: (snapshot) {
              if (snapshot.docs.isEmpty) {
                return const Text("No cars available.",
                    style: TextStyle(color: Colors.white));
              }
              return Column(
                children: snapshot.docs.map((car) {
                  Map<String, dynamic> carData =
                      car.data() as Map<String, dynamic>;
                  String category =
                      carData["expectedClass"] ?? "Unknown Category";
                  String? carPhotoUrl = carData["carImage"];

                  return Card(
                    color: Colors.grey[800], // Darker grey card background
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: carPhotoUrl != null && carPhotoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                carPhotoUrl,
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.car_rental,
                              size: 50, color: Colors.white),
                      title: Text(
                        "${carData["modelName"]} (${carData["modelYear"]}) - ${carData["type"]}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        "Seats: ${carData["seats"]}, Category: $category",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Radio<String>(
                        value: category,
                        groupValue: selectedCategory,
                        activeColor: Colors.blueAccent,
                        onChanged: (value) {
                          ref.read(selectedCategoryProvider.notifier).state =
                              value;
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permission permanently denied");
    }

    return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high));
  }
}
