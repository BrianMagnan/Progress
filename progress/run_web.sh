#!/bin/bash
# Run Flutter web app with fixed port 5555 for IndexedDB persistence
cd "$(dirname "$0")"
flutter run -d chrome --web-port=5555

