struct HospitalListView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    @State private var showAddHospital = false
    
    var body: some View {
        List {
            ForEach(viewModel.hospitals) { hospital in
                HospitalRowView(hospital: hospital)
            }
        }
        .navigationTitle("Hospitals")
        .toolbar {
            Button("Add Hospital") {
                showAddHospital = true
            }
        }
        .sheet(isPresented: $showAddHospital) {
            AddHospitalView()
        }
    }
} 