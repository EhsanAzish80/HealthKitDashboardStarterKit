//
//  ContentView.swift
//  HealthKitDashboardStarterKit
//
//  Created by Ehsan Azish on 16.05.2025.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - State Properties
    
    // Current step count fetched from HealthKit
    @State private var steps: Double = 0
    // Current heart rate fetched from HealthKit
    @State private var heartRate: Double = 0
    // Authorization status for HealthKit access
    @State private var authorized = false
    // Controls visibility of step input section
    @State private var showingInput = false
    // User input for adding steps
    @State private var inputSteps = ""
    // Last saved steps value, used for editing
    @State private var lastSavedSteps: Double?
    // Input field for editing last saved steps
    @State private var editStepInput: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title of the dashboard
                Text("📱 HealthKit Dashboard")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)

                // Description about data usage and privacy
                Text("This app uses HealthKit to read your step count and heart rate. Your health data is only stored on your device and never shared.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Show health data and input sections only if authorized
                if authorized {
                    healthDataSection
                    if let lastSteps = lastSavedSteps {
                        stepEditSection
                    }
                    stepInputSection
                } else {
                    // Inform user that HealthKit access is not granted
                    Text("HealthKit access not granted. Tap below to enable access.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // Show authorization button if not authorized
                if !authorized {
                    Button(action: {
                        // 🔐 Request authorization for HealthKit and then load data if granted
                        HealthKitHelper.handleAuthorizationAndFetch(
                            updateAuth: { self.authorized = $0 }, // Updates local state whether user granted permission
                            onSuccess: {
                                // ✅ Once authorized, fetch the user's total steps and heart rate
                                HealthKitHelper.fetchHealthData(
                                    steps: { self.steps = $0 },         // Sets the `steps` variable to today's step count
                                    heartRate: { self.heartRate = $0 }  // Sets the `heartRate` variable to most recent reading
                                )
                                // 🔓 Reveal the input section for adding new step data
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
        // MARK: - Lifecycle

        .onAppear {
            // ✅ Check if HealthKit is authorized and act accordingly.
            //
            // This function checks the current authorization status for HealthKit access.
            // It updates the `authorized` state to reflect whether the user has granted permission.
            //
            // If authorized, it fetches the current step count and heart rate data, updating the respective state variables.
            //
            // It also retrieves the last saved steps entry, if any, so the user can view or edit it.
            //
            // Finally, it sets `showingInput` to true to display the input section for adding new steps.
            //
            // This approach ensures the UI is always in sync with the user's HealthKit permissions and data.
            HealthKitHelper.checkAndHandleAuthorizationWithLastSample(
                updateAuth: { self.authorized = $0 },  // Updates authorization state to reflect permission status
                updateSteps: { self.steps = $0 },      // Updates steps state with current step count
                updateHeartRate: { self.heartRate = $0 }, // Updates heart rate state with latest reading
                updateLastEntry: { lastSteps in         // Updates last saved steps for editing purposes
                    self.lastSavedSteps = lastSteps
                    if let lastSteps = lastSteps {
                        self.editStepInput = lastSteps
                    }
                },
                showInput: { self.showingInput = true } // Shows input section once data is ready
            )
        }
    }

    // MARK: - Subviews

    /// Section displaying current health data and options to edit last saved steps.
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
    
    private var stepEditSection: some View {
        VStack{
            // Show last saved steps and editing options if available
            let lastSteps = lastSavedSteps ?? 0
                HStack {
                    Label("Last Saved Steps", systemImage: "clock")
                    Spacer()
                    Text(HealthKitHelper.formatNumber(lastSteps))
                        .bold()
                }
                
                // Input field for editing last saved steps
                TextField("Edit steps", value: $editStepInput, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                
            HStack{
                // Delete Last Entry button logically placed here
                Button("Delete Last Entry", role: .destructive) {
                    HealthKitManager.shared.deleteMostRecentStepSample { success in
                        if success {
                            self.lastSavedSteps = nil
                            HealthKitManager.shared.fetchSteps { updated in
                                self.steps = updated
                                editStepInput = 0
                            }
                        }
                    }
                }
                .font(.footnote)
                .buttonStyle(.bordered)
                Spacer()
                Button("Edit") {
                    HealthKitManager.shared.editMostRecentStepSample(newSteps: editStepInput) { success in
                        if success {
                            self.lastSavedSteps = editStepInput
                            HealthKitManager.shared.fetchSteps { updated in
                                self.steps = updated
                                editStepInput = 0
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
    }

    /// Section for adding new steps to HealthKit.
    private var stepInputSection: some View {
        VStack(spacing: 12) {
            Text("Add Steps to HealthKit")
                .font(.headline)

            // Input field for entering step count
            TextField("Enter steps", text: $inputSteps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            Button(action: {
                // Save entered steps to HealthKit and update UI accordingly
                HealthKitHelper.saveStepsToHealthKit(
                    input: inputSteps,
                    update: { newSteps in
                        self.steps = newSteps
                        HealthKitManager.shared.fetchMostRecentStepSample { latest in
                            self.lastSavedSteps = latest ?? 0
                            self.editStepInput = latest ?? 0
                        }
                    },
                    clearInput: {
                        self.inputSteps = ""
                    }
                )
            }) {
                Text("Add Steps")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
