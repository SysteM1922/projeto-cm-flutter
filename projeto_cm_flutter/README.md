# BusTracker - Flutter Project
# Authors: Guilherme Antunes [103600], Pedro Rasinhas [103541]

## Description
BusTracker is an application that helps public transport users by offering real-time bus tracking, schedule information via QR codes at bus stops, and NFC-based validation system.

## Requirements
- Flutter SDK
- ```flutter doctor``` must run without issues

## Installation
Before executing the project dependencies must be installed with
```bash
flutter pub get
```
## Running the Application
The BusTracker Validator app was developed to run **only on android devices** so after you run the command ...
```bash
flutter run
```
... you **must select a real android device**.

## Building the APK
To compile the project in order to build an apk file to be installed on an android the following command must be run.
```bash
flutter build apk
```