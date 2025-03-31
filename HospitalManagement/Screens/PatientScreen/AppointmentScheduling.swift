import SwiftUI

struct BookAppointmentView: View {
    @State private var selectedType: AppointmentType = .Consultation
    @State private var selectedDate = Date()
    @State private var notes = ""
    var selectedDoctor: String = "Dr. Jane Smith"
    var selectedDepartment: String = "Cardiology"
    var consultationFee: String = "$100"
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Doctor")
                                .font(.headline)
                            Text(selectedDoctor)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.mint.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Department")
                                .font(.headline)
                            Text(selectedDepartment)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.mint.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Consultation Fee")
                                .font(.headline)
                            Text(consultationFee)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.mint.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Text("Appointment Type")
                            .font(.headline)
                        Picker("Appointment Type", selection: $selectedType) {
                            Text("Consultation").tag(AppointmentType.Consultation)
                            Text("Emergency").tag(AppointmentType.Emergency)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if selectedType == .Consultation {
                            Text("Select Date and Time")
                                .font(.headline)
                            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding(.vertical)
                        }
                        
                        Text("Additional Notes")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mint, lineWidth: 1))
                            .padding(.bottom)
                    }
                    .padding()
                }
                
                Button(action: bookAppointment) {
                    Text("Book Appointment")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mint)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Book Appointment")
        }
    }
    
    func bookAppointment() {
        print("Appointment Booked: \(selectedType.rawValue) on \(selectedDate) with notes: \(notes)")
    }
}

// Sample preview
struct BookAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        BookAppointmentView()
    }
}

