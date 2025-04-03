//import SwiftUI
//
//struct BookAppointmentView: View {
//    @State private var selectedType: AppointmentType = .Consultation
//    @State private var selectedDate = Date()
//    @State private var notes = ""
//    @State private var selectedTimeSlot: String? = nil
//    
//    var selectedDoctor: String = "Dr. Jane Smith"
//    var selectedDepartment: String = "Cardiology"
//    var consultationFee: String = "$100"
//    
//    // Time slots from 10:00 to 5:00 with 30 min gaps
//    let timeSlots = [
//        "10:00", "10:30", 
//        "11:00", "11:30", 
//        "12:00", "12:30", 
//        "13:00", "13:30", 
//        "14:00", "14:30", 
//        "15:00", "15:30", 
//        "16:00", "16:30", 
//        "17:00"
//    ]
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                ScrollView {
//                    VStack(alignment: .leading, spacing: 16) {
//                        Group {
//                            Text("Doctor")
//                                .font(.headline)
//                            Text(selectedDoctor)
//                                .padding()
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .background(AppConfig.buttonColor)
//                                .cornerRadius(8)
//                            
//                            Text("Department")
//                                .font(.headline)
//                            Text(selectedDepartment)
//                                .padding()
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .background(AppConfig.buttonColor)
//                                .cornerRadius(8)
//                            
//                            Text("Consultation Fee")
//                                .font(.headline)
//                            Text(consultationFee)
//                                .padding()
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .background(AppConfig.buttonColor)
//                                .cornerRadius(8)
//                        }
//                        
//                        Text("Appointment Type")
//                            .font(.headline)
//                        Picker("Appointment Type", selection: $selectedType) {
//                            Text("Consultation").tag(AppointmentType.Consultation)
//                            Text("Emergency").tag(AppointmentType.Emergency)
//                        }
//                        .pickerStyle(SegmentedPickerStyle())
//                        
//                        if selectedType == .Consultation {
//                            Text("Select Date")
//                                .font(.headline)
//                            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: [.date])
//                                .datePickerStyle(GraphicalDatePickerStyle())
//                                .padding(.vertical)
//                                .onChange(of: selectedDate) { _ in
//                                    // Reset time selection when date changes
//                                    selectedTimeSlot = nil
//                                }
//                            
//                            Text("Select Time")
//                                .font(.headline)
//                                .padding(.top, 8)
//                            
//                            // Grid of time slot buttons
//                            LazyVGrid(columns: [
//                                GridItem(.flexible()),
//                                GridItem(.flexible()),
//                                GridItem(.flexible())
//                            ], spacing: 10) {
//                                ForEach(timeSlots, id: \.self) { time in
//                                    Button(action: {
//                                        selectedTimeSlot = time
//                                    }) {
//                                        Text(time)
//                                            .padding(.vertical, 8)
//                                            .padding(.horizontal, 12)
//                                            .frame(maxWidth: .infinity)
//                                            .background(selectedTimeSlot == time ? Color.mint : Color.mint.opacity(0.1))
//                                            .foregroundColor(selectedTimeSlot == time ? .white : .primary)
//                                            .cornerRadius(8)
//                                    }
//                                    .buttonStyle(BorderlessButtonStyle()) // Makes only the button tappable, not the whole area
//                                }
//                            }
//                            .padding(.bottom, 8)
//                            
//                            if selectedTimeSlot != nil {
//                                Text("Selected time: \(selectedTimeSlot!)")
//                                    .font(.subheadline)
//                                    .foregroundColor(.mint)
//                                    .padding(.bottom, 8)
//                            }
//                        }
//                        
//                        Text("Additional Notes")
//                            .font(.headline)
//                        TextEditor(text: $notes)
//                            .frame(height: 100)
//                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mint, lineWidth: 1))
//                            .padding(.bottom)
//                    }
//                    .padding()
//                }
//                
//                Button(action: bookAppointment) {
//                    Text("Book Appointment")
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(isValidForm ? AppConfig.buttonColor : Color.gray)
//                        .cornerRadius(10)
//                        .padding(.horizontal)
//                }
//                .disabled(!isValidForm)
//                .padding(.bottom)
//            }
//            .navigationTitle("Book Appointment")
//        }
//    }
//    
//    var isValidForm: Bool {
//        if selectedType == .Consultation {
//            return selectedTimeSlot != nil
//        }
//        return true
//    }
//    
//    func bookAppointment() {
//        // Create a combined date and time
//        if let timeString = selectedTimeSlot, selectedType == .Consultation {
//            let timeComponents = timeString.split(separator: ":")
//            if timeComponents.count == 2,
//               let hour = Int(timeComponents[0]),
//               let minute = Int(timeComponents[1]) {
//                
//                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
//                dateComponents.hour = hour
//                dateComponents.minute = minute
//                
//                if let appointmentDateTime = Calendar.current.date(from: dateComponents) {
//                    print("Appointment Booked: \(selectedType.rawValue) on \(appointmentDateTime) with notes: \(notes)")
//                }
//            }
//        } else {
//            // For emergency appointments without time selection
//            print("Appointment Booked: \(selectedType.rawValue) on \(selectedDate) with notes: \(notes)")
//        }
//    }
//}
//
//// Sample preview
//struct BookAppointmentView_Previews: PreviewProvider {
//    static var previews: some View {
//        BookAppointmentView()
//    }
//}
//
