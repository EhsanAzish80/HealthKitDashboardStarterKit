//
//  HealthKitManage.swift
//  HealthKitDashboardStarterKit
//
//  Created by Ehsan Azish on 16.05.2025.
//

import HealthKit

/// HealthKitManager is a singleton class responsible for:
/// - Requesting HealthKit authorization
/// - Fetching and saving health data (steps and heart rate)
/// - Checking current authorization status
///
/// 🧠 Before using this class:
/// 1. Go to Signing & Capabilities in your target and add the "HealthKit" entitlement.
/// 2. In Info.plist, add the following keys with descriptive values:
///    - NSHealthShareUsageDescription: "This app reads your health data to show insights."
///    - NSHealthUpdateUsageDescription: "This app can update your health data if you allow it."
///
/// ⚠️ All HealthKit APIs require running on a real device (not the simulator).
/// ⚙️ All operations that interact with HealthKit should be performed after proper authorization.

final class HealthKitManager {
    static let shared = HealthKitManager() // Singleton instance
    private let healthStore = HKHealthStore()

    private init() {}

    /// Requests permission to read and write HealthKit data.
    /// Call this early in the app (e.g. at login or onboarding).
    /// - Parameters:
    ///   - completion: Returns `true` if permission granted, else `false`.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        // Example types to read and write: step count and heart rate
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false)
            return
        }

        let readTypes: Set<HKObjectType> = [stepCountType, heartRateType]
        let writeTypes: Set<HKSampleType> = [stepCountType] // Only step count is writable here

        // Present the system authorization dialog
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    /// Checks whether the app is authorized to access the required HealthKit types.
    /// - Parameter completion: Returns `true` if authorized for both step count and heart rate.
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false)
            return
        }

        let stepStatus = healthStore.authorizationStatus(for: stepType)
        let heartStatus = healthStore.authorizationStatus(for: heartRateType)

        let authorized = (stepStatus == .sharingAuthorized) && (heartStatus == .sharingAuthorized)
        DispatchQueue.main.async {
            completion(authorized)
        }
    }

    /// Fetches today's total steps.
    /// - Parameter completion: Returns the total number of steps as a `Double`.
    func fetchSteps(completion: @escaping (Double) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async {
                completion(steps)
            }
        }
        healthStore.execute(query)
    }
    
    /// Fetches the most recent step sample's value (not total of the day).
    func fetchMostRecentStepSample(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil)
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let value = sample.quantity.doubleValue(for: .count())
            DispatchQueue.main.async {
                completion(value)
            }
        }

        healthStore.execute(query)
    }

    /// Fetches the most recent heart rate sample.
    /// - Parameter completion: Returns the heart rate in BPM as a `Double`.
    func fetchHeartRate(completion: @escaping (Double) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(0) }
                return
            }
            let bpm = sample.quantity.doubleValue(for: .init(from: "count/min"))
            DispatchQueue.main.async { completion(bpm) }
        }
        healthStore.execute(query)
    }

    /// Saves a step count entry for the current time.
    /// - Parameters:
    ///   - steps: Number of steps to write to HealthKit.
    ///   - completion: Called once the sample has been saved.
    func saveSteps(steps: Double, completion: @escaping () -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let quantity = HKQuantity(unit: .count(), doubleValue: steps)
        let now = Date()
        let sample = HKQuantitySample(type: type, quantity: quantity, start: now, end: now)

        healthStore.save(sample) { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    // MARK: - Editing Health Data
    //
    /// Edits the most recent step sample with a new value.
    /// ⚠️ This function deletes the most recent step entry and replaces it.
    /// Use carefully, and only if your app has a valid reason to allow edits.
    ///
    /// - Parameters:
    ///   - newSteps: New step count value to overwrite
    ///   - completion: Called when edit completes
    ///
    /// ### Usage
    /// Call this method if you want to allow your user to correct their most recent step entry (for example, if your app lets users log steps manually and they made a mistake).
    /// **Warning:** Editing historical HealthKit data is discouraged unless you have a strong use case. This function only edits the most recent entry and does so by deleting the old sample and saving a new one with the same time range but a new value.
    ///
    /// Example:
    /// ```
    /// HealthKitManager.shared.editMostRecentStepSample(newSteps: 5000) { success in
    ///     print(success ? "Step sample updated!" : "Failed to update step sample.")
    /// }
    /// ```
    func editMostRecentStepSample(newSteps: Double, completion: @escaping (Bool) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(false)
            return
        }

        // Fetch the most recent step entry
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            // Delete old sample
            self.healthStore.delete(sample) { success, _ in
                guard success else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }

                // Save new sample with same time range
                let newQuantity = HKQuantity(unit: .count(), doubleValue: newSteps)
                let newSample = HKQuantitySample(type: type, quantity: newQuantity, start: sample.startDate, end: sample.endDate)

                self.healthStore.save(newSample) { saveSuccess, _ in
                    DispatchQueue.main.async {
                        completion(saveSuccess)
                    }
                }
            }
        }

        healthStore.execute(query)
    }

    /// Deletes the most recent step sample added by this app.
    /// ⚠️ This will only affect the step entry that was most recently saved, not the full day's total unless that was the only entry.
    func deleteMostRecentStepSample(completion: @escaping (Bool) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(false)
            return
        }
        // Only delete samples that were added by this app
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let sourcePredicate = HKQuery.predicateForObjects(from: HKSource.default())
        let query = HKSampleQuery(sampleType: type, predicate: sourcePredicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            self.healthStore.delete(sample) { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }

        healthStore.execute(query)
    }
}

// 🚀 To extend this for other data types (e.g. calories, distance, weight):
// 1. Add the corresponding HKQuantityTypeIdentifier (e.g. .activeEnergyBurned).
// 2. Add to readTypes/writeTypes in `requestAuthorization`.
// 3. Add new fetch or save methods using HKStatisticsQuery or HKSampleQuery.
//
// Example:
// let calorieType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
// Add calorieType to readTypes/writeTypes
// Then query using .kilocalorie() as the unit.


// 📊 Common HealthKit Identifiers Reference
//
// | Identifier                       | Type            | Unit                        | Read/Write Availability |
// |----------------------------------|------------------|------------------------------|-------------------------|
// | stepCount                        | Quantity         | .count()                    | Read/Write              |
// | heartRate                        | Quantity         | .init(from: "count/min")    | Read                    |
// | activeEnergyBurned              | Quantity         | .kilocalorie()              | Read/Write              |
// | distanceWalkingRunning          | Quantity         | .meter()                    | Read/Write              |
// | bodyMass                        | Quantity         | .gramUnit(with: .kilo)      | Read/Write              |
// | height                          | Quantity         | .meter()                    | Read/Write              |
// | bodyFatPercentage              | Quantity         | .percent()                  | Read/Write              |
// | sleepAnalysis                   | Category         | HKCategoryValueSleepAnalysis| Read                    |
// | dietaryEnergyConsumed           | Quantity         | .kilocalorie()              | Read/Write              |
// | water                           | Quantity         | .liter()                    | Read/Write              |
// | respiratoryRate                 | Quantity         | .init(from: "count/min")    | Read                    |
// | oxygenSaturation                | Quantity         | .percent()                  | Read                    |
//
// ✅ To use these, add the appropriate identifier to your readTypes/writeTypes.
// Example:
// let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
//
