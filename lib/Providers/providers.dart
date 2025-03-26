import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

final rideApprovalNotifierProvider =
    StateNotifierProvider<RideApprovalNotifier, RideApprovalState>(
  (ref) => RideApprovalNotifier(),
);

class RideApprovalState {
  final String? rentalId;
  final bool isPaymentCompleted;
  final Map<String, dynamic>? rideDetails;
  final bool isLoading;

  RideApprovalState({
    this.rentalId,
    this.isPaymentCompleted = false,
    this.rideDetails,
    this.isLoading = true,
  });

  RideApprovalState copyWith({
    String? rentalId,
    bool? isPaymentCompleted,
    Map<String, dynamic>? rideDetails,
    bool? isLoading,
  }) {
    return RideApprovalState(
      rentalId: rentalId ?? this.rentalId,
      isPaymentCompleted: isPaymentCompleted ?? this.isPaymentCompleted,
      rideDetails: rideDetails ?? this.rideDetails,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RideApprovalNotifier extends StateNotifier<RideApprovalState> {
  late Razorpay _razorpay;

  RideApprovalNotifier() : super(RideApprovalState()) {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void disposeRazorpay() {
    _razorpay.clear();
  }

  /// **Fetch Latest Active Ride for User**
  Future<void> fetchRideForUser(String userId) async {
    try {
      state = state.copyWith(isLoading: true);

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('rental_history')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Ready for Ride')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      var rideData = snapshot.docs.first.data() as Map<String, dynamic>;
      String rentalId = snapshot.docs.first.id;

      // Fetch owner details
      DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(rideData['ownerId'])
          .get();

      String ownerName = ownerDoc.exists
          ? ownerDoc['name'] ?? 'Unknown Owner'
          : 'Unknown Owner';
      String ownerPhone = ownerDoc.exists ? ownerDoc['phone'] ?? 'N/A' : 'N/A';

      // Merge Data
      rideData['ownerName'] = ownerName;
      rideData['ownerPhone'] = ownerPhone;

      // Update state
      state = state.copyWith(
          rentalId: rentalId, rideDetails: rideData, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// **Start Payment**
  void startPayment(double totalFare) {
    var options = {
      'key': 'rzp_test_ZbZoAjOgS6FA5C', // ✅ Replace with your Razorpay API Key
      'amount': (totalFare / 1000).toInt(),
      'currency': 'INR',
      'name': 'CoolCar Rentals',
      'description': 'Payment for Ride',
    };

    _razorpay.open(options);
  }

  /// **Handle Payment Success**
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Update Firestore
    await FirebaseFirestore.instance
        .collection('rental_history')
        .doc(state.rentalId)
        .update({
      'paymentStatus': 'Paid',
      'paymentId': response.paymentId,
    });

    state = state.copyWith(isPaymentCompleted: true);
  }

  /// **Complete Ride**
  Future<void> completeRide(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('rental_history')
        .doc(state.rentalId)
        .update({
      'status': 'Completed',
    });
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  /// **Handle Payment Failure**
  void _handlePaymentError(PaymentFailureResponse response) {}

  /// **Handle External Wallet**
  void _handleExternalWallet(ExternalWalletResponse response) {}
}

final carDetailsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collectionGroup("cars")
      .where("deleted", isEqualTo: false)
      .where("openForRent", isEqualTo: true)
      .snapshots();
});

/// **📌 Location Providers**
final pickupLocationProvider = StateProvider<LatLng?>((ref) => null);
final destinationLocationProvider = StateProvider<LatLng?>((ref) => null);

/// **📅 Date Selection Providers**
final pickupDateProvider = StateProvider<DateTime?>((ref) => null);
final returnDateProvider = StateProvider<DateTime?>((ref) => null);

/// **📌 Function: Convert Address to LatLng**
Future<LatLng> getLatLngFromAddress(String address) async {
  List<Location> locations = await locationFromAddress(address);
  if (locations.isNotEmpty) {
    return LatLng(locations.first.latitude, locations.first.longitude);
  }

  return const LatLng(0, 0);
}

/// **📌 Calculate Days Between Pickup & Return**
int calculateDays(DateTime? pickupDate, DateTime? returnDate) {
  if (pickupDate != null && returnDate != null) {
    return returnDate.difference(pickupDate).inDays + 1;
  }
  return 1;
}

/// **📌 Send Rental Request**
final sendRentalRequestProvider = Provider((ref) {
  return (String pickupLocation, String destinationLocation,
      DateTime pickupDate, DateTime returnDate, String category) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pickupLatLng = await getLatLngFromAddress(pickupLocation);
    final destinationLatLng = await getLatLngFromAddress(destinationLocation);
    final numDays = calculateDays(pickupDate, returnDate);

    await FirebaseFirestore.instance.collection("rental_requests").add({
      "userId": user.uid,
      "pickupLocation": "${pickupLatLng.latitude},${pickupLatLng.longitude}",
      "destination":
          "${destinationLatLng.latitude},${destinationLatLng.longitude}",
      "pickupDate":
          Timestamp.fromDate(pickupDate), // ✅ Store as Firestore Timestamp
      "returnDate": Timestamp.fromDate(returnDate),
      "days": numDays,
      "category": category,
      "status": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    });
  };
});

/// 🔹 Fetch Latest Rental History for the User
final rentalHistoryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  String userId = FirebaseAuth.instance.currentUser!.uid;

  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('rental_history')
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: 'Ready for Ride')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return {
      'rentalId': snapshot.docs.first.id,
      'totalFare': snapshot.docs.first['totalFare']?.toDouble() ?? 0.0,
      'paymentStatus': snapshot.docs.first['paymentStatus'] ?? 'Pending',
    };
  }
  return null;
});
