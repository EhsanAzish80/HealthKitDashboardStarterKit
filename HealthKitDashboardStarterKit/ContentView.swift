//
//  ContentView.swift
//  HealthKitDashboardStarterKit
//
//  Created by Ehsan Azish on 16.05.2025.
//

import SwiftUI

struct ContentView: View {
    
    @State private var steps: Double = 0
    @State private var heartRate: Double = 0
    @State private var authorized = false
    @State private var showingInput = false
    @State private var inputSteps = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("📱 HealthKit Dashboard")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)

                Text("This app uses HealthKit to read your step count and heart rate. Your health data is only stored on your device and never shared.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if authorized {
                    healthDataSection
                    stepInputSection
                } else {
                    Text("HealthKit access not granted. Tap below to enable access.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                if !authorized {
                    Button(action: {
                        HealthKitHelper.handleAuthorizationAndFetch(
                            updateAuth: { self.authorized = $0 },
                            onSuccess: {
                                HealthKitHelper.fetchHealthData(
                                    steps: { self.steps = $0 },
                                    heartRate: { self.heartRate = $0 }
                                )
                                self.showingInput = true
                            }
                        )
                    }) {
                        Label("Authorize Health Access", systemImage: "heart.text.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            HealthKitManager.shared.checkAuthorizationStatus { isAuthorized in
                self.authorized = isAuthorized
                if isAuthorized {
                    HealthKitHelper.fetchHealthData(
                        steps: { self.steps = $0 },
                        heartRate: { self.heartRate = $0 }
                    )
                } else {
                    HealthKitHelper.handleAuthorizationAndFetch(
                        updateAuth: { self.authorized = $0 },
                        onSuccess: {
                            HealthKitHelper.fetchHealthData(
                                steps: { self.steps = $0 },
                                heartRate: { self.heartRate = $0 }
                            )
                            self.showingInput = true
                        }
                    )
                }
            }
        }
    }

    private var healthDataSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Steps", systemImage: "figure.walk")
                Spacer()
                Text(HealthKitHelper.formatNumber(steps))
                    .bold()
            }

            HStack {
                Label("Heart Rate", systemImage: "heart.fill")
                Spacer()
                Text("\(HealthKitHelper.formatNumber(heartRate)) bpm")
                    .bold()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var stepInputSection: some View {
        VStack(spacing: 12) {
            Text("Add Steps to HealthKit")
                .font(.headline)

            TextField("Enter steps", text: $inputSteps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            Button(action: {
                HealthKitHelper.saveStepsToHealthKit(
                    input: inputSteps,
                    update: { self.steps = $0 },
                    clearInput: {
                        self.inputSteps = ""
                    }
                )
            }) {
                Label("Add Steps", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
