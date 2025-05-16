//
//  HealthKitHelper.swift
//  HealthKitDashboardStarterKit
//
//  Created by Ehsan Azish on 16.05.2025.
//

import Foundation

import HealthKit

struct HealthKitHelper {
    static func formatNumber(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }

    static func fetchHealthData(steps: @escaping (Double) -> Void, heartRate: @escaping (Double) -> Void) {
        HealthKitManager.shared.fetchSteps { steps($0) }
        HealthKitManager.shared.fetchHeartRate { heartRate($0) }
    }

    static func handleAuthorizationAndFetch(updateAuth: @escaping (Bool) -> Void, onSuccess: @escaping () -> Void) {
        HealthKitManager.shared.requestAuthorization { success in
            updateAuth(success)
            if success {
                onSuccess()
            }
        }
    }

    static func saveStepsToHealthKit(input: String, update: @escaping (Double) -> Void, clearInput: @escaping () -> Void) {
        if let value = Double(input) {
            HealthKitManager.shared.saveSteps(steps: value) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    HealthKitManager.shared.fetchSteps { updatedSteps in
                        update(updatedSteps)
                        clearInput()
                    }
                }
            }
        }
    }
}
