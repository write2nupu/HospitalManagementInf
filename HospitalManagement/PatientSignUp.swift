//
//  PatientSignUp.swift
//  HospitalManagement
//
//  Created by Nupur on 18/03/25.
//

import SwiftUI

struct PatientSignUpView: View {
    @State private var progress: Double = 0.0  // Tracks progress
    @State private var path: [String] = [] // Navigation Path

    var body: some View {
        NavigationStack(path: $path) {
            PersonalInfoView(progress: $progress, path: $path)
                .navigationDestination(for: String.self) { view in
                    if view == "MedicalInfoView" {
                        MedicalInfoView(progress: $progress, path: $path)
                    } else if view == "PatientDashboardView" {
                        PatientDashboardView()
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Personal Info View
struct PersonalInfoView: View {
    @Binding var progress: Double
    @Binding var path: [String]

    @State private var fullName = ""
    @State private var gender = "Select Gender"
    @State private var dateOfBirth = Date()
    @State private var contactNumber = ""
    @State private var email = ""

    let genders = ["Select Gender", "Male", "Female", "Other"]

    var body: some View {
        VStack {
            ProgressBarView(progress: progress)
                .padding(.bottom, 10)

            VStack(spacing: 15) {
                Text("Personal Information")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                CustomTextField(placeholder: "Full Name", text: $fullName)

                // Gender Dropdown
                VStack(alignment: .leading, spacing: 5) {
                    Text("Gender").font(.headline)
                    Menu {
                        ForEach(genders, id: \..self) { gender in
                            Button(gender) {
                                self.gender = gender
                            }
                        }
                    } label: {
                        HStack {
                            Text(gender)
                                .foregroundColor(gender == "Select Gender" ? .gray : .black)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.mint.opacity(0.2))
                        .cornerRadius(10)
                    }
                }

                CustomTextField(placeholder: "Contact Number", text: $contactNumber, keyboardType: .phonePad)
                CustomTextField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress)

                Button("Next") {
                    progress = 0.5
                    path.append("MedicalInfoView")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.mint)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 15)
            }
            .padding()
            Spacer()
        }
    }
}

// Medical Info View
struct MedicalInfoView: View {
    @Binding var progress: Double
    @Binding var path: [String]

    @State private var bloodGroup = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""
    @State private var medications = ""
    @State private var pastSurgeries = ""
    @State private var emergencyContact = ""

    var body: some View {
        VStack {
            ProgressBarView(progress: progress)

            Spacer(minLength: 10)

            VStack(spacing: 15) {
                Text("Medical Information")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                CustomTextField(placeholder: "Blood Group", text: $bloodGroup)
                CustomTextField(placeholder: "Allergies (if any)", text: $allergies)
                CustomTextField(placeholder: "Existing Medical Conditions", text: $medicalConditions)
                CustomTextField(placeholder: "Current Medications", text: $medications)
                CustomTextField(placeholder: "Past Surgeries/Procedures", text: $pastSurgeries)
                CustomTextField(placeholder: "Emergency Contact", text: $emergencyContact, keyboardType: .phonePad)

                Button("Complete") {
                    progress = 1.0
                    path.append("PatientDashboardView")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.mint)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 15)
            }
            .padding()
            Spacer()
        }
    }
}

// Patient Dashboard (Placeholder)
struct PatientDashboardView: View {
    var body: some View {
        VStack {
            Text("Welcome to Your Dashboard!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.mint)
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.mint)
                .padding()
            Text("You’re all set!")
                .font(.title2)
        }
        .navigationBarBackButtonHidden(true)
        .padding()
    }
}

// Progress Bar View
struct ProgressBarView: View {
    var progress: Double

    var body: some View {
        ProgressView(value: progress, total: 1.0)
            .progressViewStyle(LinearProgressViewStyle(tint: .mint))
            .padding(.top, 20)
            .padding(.horizontal)
    }
}

// Custom Text Field
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(placeholder).font(.headline)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(Color.mint.opacity(0.2))
                .cornerRadius(10)
        }
    }
}

// Preview
struct PatientSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        PatientSignUpView()
    }
}
