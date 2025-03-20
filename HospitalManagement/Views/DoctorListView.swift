struct DoctorListView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    let hospitalId: UUID
    
    var doctors: [Doctor] {
        viewModel.getDoctorsByHospital(hospitalId: hospitalId)
    }
    
    var body: some View {
        List {
            ForEach(doctors) { doctor in
                DoctorRowView(doctor: doctor)
            }
        }
        .navigationTitle("Doctors")
    }
} 