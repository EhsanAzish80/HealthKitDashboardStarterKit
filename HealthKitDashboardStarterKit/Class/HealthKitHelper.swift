//
//  HealthKitHelper.swift
//  HealthKitDashboardStarterKit
//
//  Created by Ehsan Azish on 16.05.2025.
//

//
//  HealthKitHelper.swift
//  HealthKitDashboardStarterKit
//
//  Created by Ehsan Azish on 16.05.2025.
//

import Foundation
import HealthKit

/// A utility struct to simplify interactions between SwiftUI views and the HealthKitManager.
/// It abstracts logic for fetching, saving, and checking authorization, and helps clean up view files.
///
/// ✅ Use this helper to keep `ContentView` readable and concise.
/// ✅ All methods here are static so they can be called directly without initialization.
struct HealthKitHelper {

    /// Formats a Double value into a rounded string.
    /// Used to present step and heart rate values in a friendly format.
    static func formatNumber(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }
    
    /// Fetches the total step count and latest heart rate reading from HealthKit.
    /// - Parameters:
    ///   - steps: Closure returning total steps for the current day.
    ///   - heartRate: Closure returning the most recent heart rate.
    static func fetchHealthData(steps: @escaping (Double) -> Void, heartRate: @escaping (Double) -> Void) {
        HealthKitManager.shared.fetchSteps { steps($0) }
        HealthKitManager.shared.fetchHeartRate { heartRate($0) }
    }

    /// Requests authorization from the user to read/write HealthKit data, then calls `onSuccess` if granted.
    /// - Parameters:
    ///   - updateAuth: Closure to update UI based on authorization result.
    ///   - onSuccess: Executes if authorization is granted.
    static func handleAuthorizationAndFetch(updateAuth: @escaping (Bool) -> Void, onSuccess: @escaping () -> Void) {
        HealthKitManager.shared.requestAuthorization { success in
            updateAuth(success)
            if success {
                onSuccess()
            }
        }
    }

    /// Saves a step count entry to HealthKit and then updates the UI.
    /// - Parameters:
    ///   - input: String value entered by user to be converted into step count.
    ///   - update: Closure to update the total steps shown in the UI.
    ///   - clearInput: Closure to reset the input field after save.
    static func saveStepsToHealthKit(input: String, update: @escaping (Double) -> Void, clearInput: @escaping () -> Void) {
        if let value = Double(input) {
            HealthKitManager.shared.saveSteps(steps: value) {
                HealthKitManager.shared.fetchSteps { updatedSteps in
                    update(updatedSteps)
                    clearInput()
                }
            }
        }
    }

    /// Checks HealthKit authorization and fetches step, heart rate, and most recent step sample if permitted.
    /// - Parameters:
    ///   - updateAuth: Updates UI authorization flag.
    ///   - updateSteps: Returns the current day's total steps.
    ///   - updateHeartRate: Returns the most recent heart rate.
    ///   - updateLastEntry: Returns the most recent step entry sample value.
    ///   - showInput: Executes when UI should reveal input controls.
    static func checkAndHandleAuthorizationWithLastSample(
        updateAuth: @escaping (Bool) -> Void,
        updateSteps: @escaping (Double) -> Void,
        updateHeartRate: @escaping (Double) -> Void,
        updateLastEntry: @escaping (Double?) -> Void,
        showInput: @escaping () -> Void
    ) {
        HealthKitManager.shared.checkAuthorizationStatus { isAuthorized in
            updateAuth(isAuthorized)
            if isAuthorized {
                fetchHealthData(steps: updateSteps, heartRate: updateHeartRate)
                HealthKitManager.shared.fetchMostRecentStepSample { quantity in
                    updateLastEntry(quantity)
                }
                showInput()
            } else {
                handleAuthorizationAndFetch(updateAuth: updateAuth) {
                    fetchHealthData(steps: updateSteps, heartRate: updateHeartRate)
                    HealthKitManager.shared.fetchMostRecentStepSample { quantity in
                        updateLastEntry(quantity)
                    }
                    showInput()
                }
            }
        }
    }
}
