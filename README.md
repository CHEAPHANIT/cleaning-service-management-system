# CleanNow: Cleaning Service Booking and Management

CleanNow is a Flutter application for booking and managing home, office, and apartment cleaning services. It provides separate customer, cleaner, and administrator experiences backed by a Python REST API and SQLite database.

This README is written for non-technical readers who want to understand the project and technical readers who want to install, test, or extend it.

> **Project notice:** CleanNow is a university/demo project. Authentication and role-based screens are implemented for demonstration, but the API does not currently issue access tokens or enforce production-grade authorization. Do not deploy it with real customer data or payments without adding server-side access control and a production payment provider.

## Table of Contents

- [Why This System Exists](#why-this-system-exists)
- [Main Goal](#main-goal)
- [What Users Can Do](#what-users-can-do)
- [How the Complete Process Works](#how-the-complete-process-works)
- [System Architecture](#system-architecture)
- [Quick Setup](#quick-setup)
- [Run on Other Devices](#run-on-other-devices)
- [Demo Accounts](#demo-accounts)
- [How to Test the Complete System](#how-to-test-the-complete-system)
- [Automated Tests](#automated-tests)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [API Overview](#api-overview)
- [Database Overview](#database-overview)
- [Troubleshooting](#troubleshooting)

## Why This System Exists

Booking a cleaning service often involves scattered phone calls, unclear pricing, uncertain cleaner availability, and limited visibility after a booking is made. Cleaning businesses also need a practical way to manage customers, cleaners, services, schedules, assignments, and revenue.

CleanNow brings these activities into one application. Customers can find and book services, administrators can organize the operation, and cleaners can follow assigned work from departure through completion.

## Main Goal

The goal is to provide one shared cleaning-service workflow for every participant:

```text
Customer selects a service and booking details
                      ↓
          Booking is saved as Pending
                      ↓
        Admin accepts and assigns a cleaner
                      ↓
Cleaner updates On the Way → Arrived → In Progress → Completed
                      ↓
      Customer follows progress and leaves a review
```

## What Users Can Do

### Customers

- Complete onboarding, register, log in, log out, and request a password reset.
- Browse, search, filter, sort, and refresh cleaning services.
- View service tasks, ratings, duration, and pricing.
- Save favorite services.
- Book with a schedule, address, property details, extras, instructions, and payment method.
- See automatic price and duration calculations.
- Follow booking history, cleaner assignment, and the status timeline.
- Cancel eligible bookings and review completed work.
- Maintain a profile and saved addresses.
- Read notifications and browse products, tips, and promotions.

### Cleaners

- View assigned and upcoming jobs on a cleaner dashboard and schedule.
- Open job details and advance supported tracking statuses.
- Upload before/after photos and save completion notes.
- Review performance, achievements, reviews, and calculated pay.
- Update availability when no active job requires the cleaner to remain busy.

### Administrators

- View totals for bookings, customers, cleaners, and revenue.
- Search and manage customers and staff accounts.
- Add, edit, activate, or deactivate cleaners and maintain hourly rates.
- Manage service packages.
- Accept, reject, cancel, and inspect bookings.
- Assign available cleaners to accepted bookings.
- Review revenue, cleaner pay, service performance, and exportable reports.

## How the Complete Process Works

### User journey

1. **Create an account:** A customer registers and signs in.
2. **Choose a service:** The customer searches the catalog and opens a service.
3. **Configure the booking:** Property details, schedule, extras, payment, and instructions are entered.
4. **Calculate the price:** The app combines the base price with property-size and add-on charges.
5. **Submit the request:** The backend stores the booking and creates notifications.
6. **Review and assign:** An administrator accepts it and assigns an available cleaner.
7. **Perform the job:** The cleaner updates each status and records task documentation.
8. **Complete and review:** The customer sees the result and can submit a rating.

### What happens during a request

```text
Flutter screen
    ↓ Provider and repository
Dio REST/JSON request
    ↓
Python HTTP API
    ↓ validation and workflow rules
SQLite server database
    ↓ JSON response
Flutter updates the role-based screen
```

When the API is unavailable, supported mobile features can use local SQLite as a fallback. The web build uses browser preferences and in-memory collections for local fallback. Shared multi-user behavior still requires the Python API.

## System Architecture

| Layer | Technology | Responsibility |
| --- | --- | --- |
| Interface | Flutter and Material 3 | Screens, forms, navigation, and role portals |
| State | Provider | Authentication, services, bookings, admin data, favorites, products, and notifications |
| Data access | Repositories and Dio | REST requests and local fallback coordination |
| Backend | Python standard library | REST endpoints, workflow rules, notifications, and Swagger hosting |
| Shared data | SQLite | Users, services, bookings, assignments, reviews, and related records |
| Device fallback | sqflite / SharedPreferences | Mobile fallback, onboarding, session, and lightweight web persistence |
| External catalog | DummyJSON | Demo products with server caching and built-in fallback data |
| Files | pdf / image_picker | PDF reports and cleaner task photos |

## Quick Setup

### Requirements

- Flutter SDK with Dart 3.12 or later
- Python 3 with SQLite support
- Chrome or an Android/iOS development environment
- Port `8080` available

### 1. Install dependencies

```powershell
cd C:\path\to\CleanNow
flutter pub get
```

### 2. Start the shared API

```powershell
python server\clean_now_api.py
```

Keep this terminal open. The API creates and seeds `server/cleannow_server.db` automatically.

| Check | Address | Expected result |
| --- | --- | --- |
| Status | http://localhost:8080/api/status | JSON containing `"status": "ok"` |
| Swagger UI | http://localhost:8080/docs | Interactive API documentation |
| OpenAPI | http://localhost:8080/openapi.json | OpenAPI 3 JSON document |

### 3. Start Flutter

Open a second terminal:

```powershell
flutter run -d chrome --web-port 55226
```

For a connected mobile target, use `flutter run`. Stop either process with `Ctrl+C`.

## Run on Other Devices

The default API URL is `http://localhost:8080/api`. Override it with `CLEAN_NOW_API_URL`.

Android Emulator:

```powershell
flutter run --dart-define=CLEAN_NOW_API_URL=http://10.0.2.2:8080/api
```

Physical device on the same network:

```powershell
flutter run --dart-define=CLEAN_NOW_API_URL=http://YOUR_COMPUTER_LAN_IP:8080/api
```

Allow port `8080` through the firewall when testing from another device. Do not use `localhost` on a physical phone because it refers to the phone itself.

## Demo Accounts

| Role | Email | Password |
| --- | --- | --- |
| Administrator | `admin@cleannow.demo` | `demo123` |

Cleaner credentials are created by each applicant in the cleaner application form and become active after admin approval. Register a new account to test the customer journey.

## How to Test the Complete System

Follow this acceptance test from top to bottom with a new customer email.

### Step 0: Confirm the system is ready

1. Start the API.
2. Open http://localhost:8080/api/status.
3. Start Flutter and wait for onboarding or sign-in.

Expected: the status endpoint reports `ok`, the app opens, and first-time users see onboarding.

### Step 1: Register and sign in

1. Register with a valid name, email, phone, and password.
2. Sign out after reaching the customer home screen.
3. Sign in again with the same credentials.

Expected: registration opens the customer portal, duplicate email is rejected, and login works after logout.

### Step 2: Browse services

1. Search for `Deep Cleaning`.
2. Try a category filter and sorting.
3. Open the service and mark it as a favorite.

Expected: the list updates, details show tasks and pricing, and the service appears in Favorites.

### Step 3: Create a booking

| Input | Test value |
| --- | --- |
| Service | `Deep Cleaning` |
| Property | `Apartment` |
| Rooms / bathrooms | `2` / `1` |
| Date | A future date |
| Address | `123 Test Street, Phnom Penh` |
| Extra | Any available extra |
| Payment | `Cash` |
| Instruction | `Please call on arrival.` |

Expected: the total responds to size/extras, invalid inputs are rejected, and a new `Pending` booking opens.

### Step 4: Accept and assign as admin

1. Sign in as the demo administrator.
2. Locate the booking and change it to `Accepted`.
3. Assign an available cleaner.

Expected: it becomes `Cleaner Assigned`, the cleaner becomes busy, and duplicate/unavailable assignment is rejected.

### Step 5: Complete the job as cleaner

1. Sign in as the assigned cleaner.
2. Open the job and advance through `On the Way`, `Arrived`, `In Progress`, and `Completed`.
3. Add task photos and completion notes where supported.

Expected: only valid transitions succeed, documentation remains attached, and completion makes the cleaner available.

### Step 6: Review as the customer

1. Sign back in as the customer.
2. Open the completed booking and submit a rating and comment.

Expected: the timeline and cleaner are visible, one review is saved, and another customer's booking cannot be opened.

### Step 7: Check supporting features

Test saved addresses, notifications, products, tips, admin finance, and PDF reporting.

Expected: shared changes persist while the API is running, products use remote/cache/fallback data, and admin totals reflect bookings.

### Negative-input checklist

| Test | Expected result |
| --- | --- |
| Register the same email twice | Duplicate-email error |
| Invalid email or wrong password | Authentication is rejected |
| Missing address or invalid schedule | Booking is not created |
| Jump directly from assigned to completed | API conflict response |
| Assign twice or assign a busy cleaner | Assignment is rejected |
| Open another customer's booking in the UI | Permission message |

## Automated Tests

```powershell
flutter analyze
flutter test
```

Tests cover pricing, validation, model persistence, booking privacy, booking-success navigation, promotions, address defaults, responsive cleaner screens, schedules, profiles, tracking, and documentation.

Optional build checks:

```powershell
flutter build web
flutter build apk --debug
```

The Python backend currently has no separate automated test suite. Explore endpoints through http://localhost:8080/docs.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `CLEAN_NOW_HOST` | `0.0.0.0` | API listening address |
| `CLEAN_NOW_PORT` | `8080` | API port |
| `CLEAN_NOW_DB` | `server/cleannow_server.db` | Shared database path |

Example:

```powershell
$env:CLEAN_NOW_PORT = "8090"
$env:CLEAN_NOW_DB = "C:\data\cleannow.db"
python server\clean_now_api.py
flutter run --dart-define=CLEAN_NOW_API_URL=http://localhost:8090/api
```

## Project Structure

```text
lib/
  main.dart                         application bootstrap and providers
  app.dart                          theme and routes
  core/                             constants, errors, utilities, downloads, widgets
  data/
    local/database_helper.dart     SQLite and browser fallback storage
    models/models.dart             application models
    providers/app_providers.dart   application state
    remote/clean_now_api.dart      Dio REST client
    repositories/repositories.dart data access coordination
  features/screens.dart            customer, cleaner, and admin screens
server/
  clean_now_api.py                 Python REST API and SQLite setup
  openapi.json                     API specification
  README.md                        server-specific guide
test/widget_test.dart              unit and widget tests
android/                           Android runner
ios/                               iOS runner
web/                               web runner
pubspec.yaml                       packages and SDK requirements
```

## API Overview

| Area | Main endpoints |
| --- | --- |
| Status | `GET /api/status` |
| Authentication | `POST /api/auth/register`, `/login`, `/reset-password` |
| Users | `GET /api/users`, `POST /api/users/upsert`, `DELETE /api/users/{id}` |
| Services | `GET/POST /api/services`, `DELETE /api/services/{id}` |
| Bookings | `GET/POST /api/bookings`, `PATCH /api/bookings/{id}/status` |
| Assignment | `PATCH /api/bookings/{id}/assign` |
| Documentation | `PATCH /api/bookings/{id}/documentation` |
| Favorites | `GET /api/favorites`, `POST /api/favorites/toggle` |
| Addresses | `GET /api/addresses`, `POST /api/addresses/replace` |
| Reviews | `POST /api/reviews`, `GET /api/reviews/booking/{booking_id}` |
| Notifications | `GET /api/notifications`, `PATCH /api/notifications/read-all` |
| Products | `GET /api/products` |

Production work should add token authentication and server-side role/ownership checks to protected endpoints.

## Database Overview

```text
users           customer, cleaner, and administrator profiles
services        packages, prices, duration, and availability
bookings        schedule, property, price, assignment, status, and documentation
notifications   user-specific workflow messages
favorites       customer-to-service favorites
reviews         one rating and comment per booking
products        cached DummyJSON or fallback products
addresses       customer saved service locations
```

On mobile, local `cleannow.db` fallback data contains equivalent core tables plus `cached_products`. The web fallback uses SharedPreferences for selected data.

## Troubleshooting

### The API is unavailable

- Confirm `python server\clean_now_api.py` is running.
- Open http://localhost:8080/api/status.
- Check `CLEAN_NOW_API_URL`.
- Use `10.0.2.2`, not `localhost`, from the Android emulator.

### Port 8080 is already used

Set `CLEAN_NOW_PORT` to another value and pass the same port in Flutter's `CLEAN_NOW_API_URL`.

### A physical phone cannot connect

Use the computer's LAN IP, keep both devices on the same network, allow port `8080` through the firewall, and leave `CLEAN_NOW_HOST` as `0.0.0.0`.

### Products do not load

The server caches DummyJSON products. If that request fails with an empty cache, it inserts a small fallback catalog. Check network access, restart the API, and request `/api/products` again.

### Local and server data differ

Shared data lives in `server/cleannow_server.db`; mobile fallback data lives in the device's `cleannow.db`. Start the API before Flutter to keep role workflows on the shared source of truth.

### Reset development data

Stop the API, back up anything needed, delete `server/cleannow_server.db`, and restart the server. A new database and demo records are created automatically. This permanently removes existing shared development data.
