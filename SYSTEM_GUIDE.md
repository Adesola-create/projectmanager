# Employee Clocking System

## Features
- **Barcode Scanning**: Employees scan their barcode to authenticate
- **Workflow-Based Clocking**: Sequential steps ensure complete daily tracking
- **Beautiful UI**: Modern, intuitive interface with gradient cards and animations
- **Local Storage**: SQLite database for offline functionality
- **Auto-Sync**: Automatic synchronization when internet is available

## Workflow Process

### 1. Barcode Scanning
- Open app to see barcode scanner
- Position employee barcode within the scanning frame
- System validates barcode against employee database
- Successful scan redirects to dashboard

### 2. Clock In
- Employee sees welcome screen with clock-in option
- Press "Clock In" to start the workday
- System records timestamp and shows plan submission form

### 3. Daily Plan Submission
- After clocking in, employee must submit daily plan
- Fill in the plan text area with work objectives
- Press "Submit Plan" to proceed to next step
- Plan is saved locally and synced when online

### 4. Daily Report Submission
- After plan submission, report form becomes available
- Employee documents work accomplished during the day
- Press "Submit Report" to enable clock-out option
- Report is saved locally and synced when online

### 5. Clock Out
- After report submission, clock-out card appears
- Press "Clock Out" to end the workday
- System records end timestamp and completes the cycle

## Employee Database
The system validates barcodes against a JSON employee list:
```json
[
  { "id": 1, "name": "Amina Yusuf", "barcode": "890001234501" },
  { "id": 2, "name": "Daniel Okoye", "barcode": "890001234502" },
  ...
]
```

## Technical Features
- **Local Storage**: SQLite database stores all entries offline
- **Status Tracking**: Each entry has status (clocked_in, plan_submitted, report_submitted, clocked_out)
- **Auto-Sync**: Background sync every 5 minutes when connected
- **Beautiful UI**: Gradient cards, rounded corners, proper spacing
- **Responsive Design**: Works on various screen sizes

## Setup
1. Update API endpoint in `lib/services/sync_service.dart`
2. Configure employee API in `lib/services/api_service.dart`
3. Run: `flutter pub get && flutter run`

## Permissions
- Camera: For barcode scanning
- Internet: For API synchronization
- Network State: To detect connectivity