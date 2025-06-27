# 🚖 Cool Car (User)

Cool Car User is the **customer-side Flutter app** of the CoolCar platform — a modern solution for booking private cars for rentals or taxi services. This app enables users to book available vehicles, track rides, make payments, and communicate seamlessly with vehicle owners and the CoolCar office.

---

## 📖 Project Vision

CoolCar aims to empower users to **rent privately owned vehicles** (CoolTaxis) via a trusted, office-managed network. Users can book a car, receive owner confirmations, make secure payments, and enjoy a professional service managed through real-time tracking and communication.

This app was created to simplify the user experience in:

- Booking cars with flexible pickup/drop options
- Paying through Razorpay
- Getting updates via push notifications
- Tracking ride history
- Viewing announcements and FAQs

---

## 📱 User App Features

- 📍 Select starting point and destination
- 🗓️ Set pickup date and rental duration
- 🚘 View available cars
- ✅ Send booking request
- 📬 Get acceptance notification from the owner
- 💳 Make secure payments via Razorpay
- 🕹️ Track current ride and ride history
- 📩 Receive announcements and FAQs
- 🧾 Access booking receipts and invoices
- 💬 Chat with admin support (optional)

---

## 🛠 Tech Stack

| Layer         | Technology                |
|---------------|---------------------------|
| Language      | Dart                      |
| Framework     | Flutter                   |
| Backend       | Firebase Firestore        |
| Local DB      | Hive                      |
| Payments      | Razorpay                  |
| Notifications | Firebase Cloud Messaging  |
| State Mgmt    | Riverpod                  |
| Image Upload  | Firebase Storage          |

---

## 🔐 Authentication

Users authenticate using Firebase (email/password or phone). Session state is securely stored using Hive to keep users logged in.

---

## 📂 Project Structure (Overview)

```bash
lib/
├── Main/               # Authentication pages
├── Views/               # All UI screens (Booking, Ride History, etc.)
├── widgets/               # Reusable UI components
├── providers/        # All Firebase-related logic (Riverpod)
├── models/                # Data models (User, RideRequest, Vehicle, etc.)
├── main.dart              # App entry point
````

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/younusvalasseri/cool_car_user_1.git
cd cool_car_user_1
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Setup Firebase

* Add `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS)
* Enable Firestore, Firebase Authentication, Firebase Messaging, and Firebase Storage

### 4. Run the app

```bash
flutter run
```

---

## 🔔 Notifications

* Users receive notifications for:

  * Booking confirmation
  * Ride status updates
  * Announcements and reminders

---

## 💳 Payments

* Integrated Razorpay for ride payments
* "Complete Ride" only activates after payment verification
* [CoolCar Payment Link](https://razorpay.me/@coolcar)

---

## 📎 Related Projects

| App            | Repo Link                                                                 |
| -------------- | ------------------------------------------------------------------------- |
| Cool Car Admin | [cool\_car\_admin](https://github.com/younusvalasseri/cool_car_admin)     |
| Cool Car Owner | [cool-car(owner)](https://github.com/younusvalasseri/cool-car)            |
| Cool Car User | [cool-car(owner)](https://github.com/younusvalasseri/cool_car_user_1)            |

---

## 🙋‍♂️ About the Developer

**Younus Valasseri**
Director, Institute of Automobile Technology (IAT)
GitHub: [@younusvalasseri](https://github.com/younusvalasseri)

---
