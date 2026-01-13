# Clocking System Usage

## Features
- User login/registration
- Clock in/out functionality
- Daily plan submission
- Daily report submission
- Local data storage with SQLite
- Automatic synchronization when internet is available

## How to Use

1. **Login**: Enter username and password. New users are automatically registered.

2. **Clock In**: Press "Clock In" button to start your workday.

3. **Daily Plan**: After clocking in, submit your plan for the day.

4. **Daily Report**: Throughout or at the end of the day, submit your work report.

5. **Clock Out**: Press "Clock Out" to end your workday.

6. **Logout**: Use the logout button in the app bar.

## Data Storage
- All data is stored locally using SQLite
- Data automatically syncs to server when internet connection is available
- Sync happens every 5 minutes when connected

## API Integration
To connect to your backend API, update the `_baseUrl` in `lib/services/sync_service.dart` with your actual API endpoint.

## Running the App
```bash
flutter pub get
flutter run
```