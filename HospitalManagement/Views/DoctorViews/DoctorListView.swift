struct AllDoctorsListView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.doctors) { doctor in
                DoctorRowView(doctor: doctor)
            }
        }
        .navigationTitle("All Doctors")
    }
} 