import SwiftUI
import UIKit

// MARK: - Patient Model
struct Patient {
    var fullName: String
    var gender: String
    var dateOfBirth: Date
    var contactNumber: String
    var email: String
    var bloodGroup: String
    var allergies: String
    var medicalConditions: String
    var medications: String
    var pastSurgeries: String
    var emergencyContact: String
}

struct PatientDashboardView: View {
    @State private var showHospitalList = false
    @State private var showProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 60, style: .continuous)
                        .fill(Color.mint.opacity(0.2))
                        .frame(height: UIScreen.main.bounds.height / 2)
                        .shadow(radius: 5)
                        .edgesIgnoringSafeArea(.top)
                    
                    VStack(spacing: 20) {
                        HStack {
                            Text("Dashboard")
                                .font(.largeTitle).bold()
                                .foregroundColor(.mint)
                            Spacer()
                            Button(action: {
                                showProfile = true
                            }) {
                                Image(systemName: "person.crop.circle")
                                    .font(.title)
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showProfile) {
                            ProfileViewControllerWrapper()
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("John Doe")
                                .font(.title).bold()
                            Text("Age: 30")
                            Text("Condition: Stable")
                            Text("Blood Group: O+")
                            Text("Contact: +1234567890")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 200, alignment: .leading)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.top, 50)
                }
                .edgesIgnoringSafeArea(.bottom)
                
                Button(action: {
                    showHospitalList = true
                }) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.white)
                        Text("Find Hospitals")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .frame(height: 70)
                    .background(Color.mint.opacity(0.6))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
                .sheet(isPresented: $showHospitalList) {
                    HospitalListView()
                }
                Spacer()
            }
        }
    }
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let profileData = [
        ("Full Name", "John Doe"),
        ("Age", "30"),
        ("Gender", "Male"),
        ("Blood Group", "O+"),
        ("Allergies", "None"),
        ("Medical Conditions", "Stable"),
        ("Medications", "None"),
        ("Past Surgeries", "Appendectomy"),
        ("Contact Number", "+1234567890"),
        ("Emergency Contact", "+0987654321")
    ]
    
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Patient Profile"
        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profileData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.textLabel?.text = profileData[indexPath.row].0
        cell.detailTextLabel?.text = profileData[indexPath.row].1
        return cell
    }
}

struct ProfileViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ProfileViewController {
        return ProfileViewController()
    }
    
    func updateUIViewController(_ uiViewController: ProfileViewController, context: Context) {}
}

struct PatientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        PatientDashboardView()
    }
}
