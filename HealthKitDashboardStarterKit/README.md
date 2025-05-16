# HealthKitDashboardStarterKit

A minimal, production-ready SwiftUI starter kit for integrating HealthKit into your iOS app.  
It demonstrates how to read, write, edit, and delete step data — and display a compact health dashboard.

---

## 🧠 What It Does

This starter kit includes:
- HealthKit permission handling
- Step count tracking (read/write/delete/edit)
- Heart rate monitoring
- Clean SwiftUI dashboard UI
- Fully commented code for beginners
- Modular structure (Manager + Helper + UI)

---

## ⚙️ Setup Instructions

### 1. Enable HealthKit Capabilities
- Open Xcode project settings.
- Go to **Signing & Capabilities** tab.
- Click **+ Capability** → Add **HealthKit**.

### 2. Configure `Info.plist`
Add the following keys:
```xml
<key>NSHealthShareUsageDescription</key>
<string>This app reads your health data to show insights.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>This app can update your health data if you allow it.</string>
```

### 3. Test on a Real Device
⚠️ HealthKit is not supported on the iOS Simulator.  
Build and run on a physical iPhone with Health permissions enabled.

---

## 📱 Features

- ✅ View today’s step count and most recent heart rate
- ➕ Add step count manually
- ✏️ Edit the most recent saved step entry
- 🗑️ Delete the last step entry (only those added by the app)
- 🔐 Authorization handled gracefully
- 💬 All views and methods fully documented

---

## 🧩 Folder Structure

```
📁 HealthKitDashboardStarterKit
├── HealthKitManager.swift    # Low-level HealthKit logic
├── HealthKitHelper.swift     # UI-safe helper methods
├── ContentView.swift         # SwiftUI interface
├── README.md                 # This file
```

---

## 🔧 Extending the Kit

Want to track other data types? Here's how:

| Identifier                 | Type      | Unit               | Notes                        |
|----------------------------|-----------|--------------------|------------------------------|
| `activeEnergyBurned`       | Quantity  | `.kilocalorie()`   | Calories burned              |
| `distanceWalkingRunning`   | Quantity  | `.meter()`         | Workout distance             |
| `bodyMass`                 | Quantity  | `.gramUnit(.kilo)` | Body weight                  |
| `sleepAnalysis`            | Category  | Category enum      | Sleep data                   |
| `dietaryEnergyConsumed`    | Quantity  | `.kilocalorie()`   | Nutrition                    |

1. Add identifiers to the `readTypes` or `writeTypes` in `HealthKitManager`.
2. Create methods to read/save using `HKSampleQuery` or `HKStatisticsQuery`.

---

## 📄 License

MIT License. See `LICENSE.txt`.

---

## 👨‍💻 Created by

Ehsan Azish — [3NSofts](https://github.com/ehsanazish)
