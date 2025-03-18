//
//  PatientSignUp.swift
//  HospitalManagement
//
//  Created by Nupur on 18/03/25.
//

import SwiftUI

struct PatientSignUpView: View {
    @State private var progress: Double = 0.0  // Tracks progress

    var body: some View {
        NavigationView {
            PersonalInfoView(progress: $progress)
                .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Progress Bar View (Reusable)
struct ProgressBarView: View {
    var progress: Double

    var body: some View {
        ProgressView(value: progress, total: 1.0)
            .progressViewStyle(LinearProgressViewStyle(tint: .mint))
            .padding(.top, 20)
            .padding(.horizontal)
    }
}

// MARK: - Personal Info View
struct PersonalInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var progress: Double

    @State private var fullName = ""
    @State private var gender = "Select Gender"
    @State private var dateOfBirth = Date()
    @State private var contactNumber = ""
    @State private var email = ""

    let genders = ["Select Gender", "Male", "Female", "Other"]

    var body: some View {
        VStack {
            // Progress Bar at the Top
            ProgressBarView(progress: progress)

            Spacer(minLength: 10)

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
                        ForEach(genders, id: \.self) { gender in
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

                // Date of Birth
                VStack(alignment: .leading, spacing: 5) {
                    Text("Date of Birth").font(.headline)
                    DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color.mint.opacity(0.2))
                        .cornerRadius(10)
                }

                CustomTextField(placeholder: "Contact Number", text: $contactNumber, keyboardType: .phonePad)
                CustomTextField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress)

                // Push Segue to Medical Info
                NavigationLink(destination: MedicalInfoView(progress: $progress)) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    progress = 0.5  // Increase progress to 50% when Next is tapped
                })
            }
            .padding()

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.mint)
                    Text("Back")
                        .foregroundColor(.mint)
                }
            }
        }
    }
}

// MARK: - Medical Info View
struct MedicalInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var progress: Double

    @State private var bloodGroup = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""
    @State private var medications = ""
    @State private var pastSurgeries = ""
    @State private var emergencyContact = ""

    var body: some View {
        VStack {
            // Progress Bar at the Top
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

                // Complete Button
                NavigationLink(destination: PatientDashboardView()) {
                    Text("Complete")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    progress = 1.0  // Increase progress to 100% when Complete is tapped
                })
            }
            .padding()

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.mint)
                    Text("Back")
                        .foregroundColor(.mint)
                }
            }
        }
    }
}

// MARK: - Patient Dashboard (Placeholder)
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
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(placeholder).font(.headline)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.mint.opacity(0.2))
                .cornerRadius(10)
        }
    }
}

// MARK: - Preview
struct PatientSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        PatientSignUpView()
    }
}
