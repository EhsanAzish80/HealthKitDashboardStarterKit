//
//  HealthKitManage.swift
//  HealthKitDashboardStarterKit
//
//  Created by Ehsan Azish on 16.05.2025.
//

import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false)
            return
        }

        let readTypes: Set<HKObjectType> = [stepCountType, heartRateType]
        let writeTypes: Set<HKSampleType> = [stepCountType]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

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
}
