struct ContentView: View {
    @EnvironmentObject private var viewModel: HospitalManagementViewModel
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Hospitals", destination: HospitalListView())
                NavigationLink("Admins", destination: AdminManagementView())
                NavigationLink("Departments", destination: DepartmentListView())
                NavigationLink("All Doctors", destination: AllDoctorsListView())
                NavigationLink("Patients", destination: PatientListView())
            }
            .navigationTitle("Hospital Management")
        }
    }
} 