import SwiftUI

struct InvoiceListView: View {
    @State private var invoices: [Invoice] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var selectedFilter: PaymentType? = nil
    @State private var searchText: String = ""
    @StateObject private var supabaseController = SupabaseController()
    @StateObject private var speechRecognizer = SpeechRecognizer()

    // Optional: If you want to filter by a specific patient ID
    var patientId: UUID? = nil

    var filteredInvoices: [Invoice] {
        invoices.filter { invoice in
            (selectedFilter == nil || invoice.paymentType == selectedFilter) &&
            (searchText.isEmpty || invoiceContainsSearchText(invoice, searchText: searchText))
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Search Bar with Microphone
//                SearchBars(text: $searchText, speechRecognizer: speechRecognizer)

                if isLoading {
                    ProgressView("Loading invoices...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()

                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Try Again") {
                            Task {
                                await fetchInvoices()
                            }
                        }
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .padding()
                } else if invoices.isEmpty {
                    VStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()

                        Text("No invoices found")
                            .font(.headline)

                        Text("Your invoice history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredInvoices.sorted(by: { $0.createdAt > $1.createdAt })) { invoice in
                                NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                    InvoiceRow(invoice: invoice)
                                        .padding(.horizontal)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider()
                                    .padding(.horizontal)
                            }

                            // Add extra space at the bottom to ensure content doesn't go under tab bar
                            Color.clear.frame(height: 60)
                        }
                        .background(Color(.systemBackground))
                    }
                    .refreshable {
                        await fetchInvoices()
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Invoices")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("All", action: { selectedFilter = nil })
                    ForEach(PaymentType.allCases, id: \.self) { type in
                        Button(type.rawValue.capitalized, action: { selectedFilter = type })
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                }
            }
        }
        .task {
            if invoices.isEmpty {
                await fetchInvoices()
            }
        }
        .alert(item: $speechRecognizer.errorMessage) { alertMessage in
            Alert(
                title: Text("Error"),
                message: Text(alertMessage.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func fetchInvoices() async {
        isLoading = true
        errorMessage = nil

        if let patientId = patientId {
            let fetchedInvoices = await supabaseController.fetchInvoicesByPatientId(patientId: patientId)
            if !fetchedInvoices.isEmpty {
                invoices = fetchedInvoices
            } else if invoices.isEmpty {
                errorMessage = "Unable to load invoices. Please try again later."
            }
        } else {
            let fetchedInvoices = await supabaseController.fetchAllInvoices()
            if !fetchedInvoices.isEmpty {
                invoices = fetchedInvoices
            } else if invoices.isEmpty {
                errorMessage = "Unable to load invoices. Please try again later."
            }
        }

        isLoading = false
    }

    private func invoiceContainsSearchText(_ invoice: Invoice, searchText: String) -> Bool {
        let searchTerm = searchText.lowercased()
        return invoice.paymentType.rawValue.lowercased().contains(searchTerm) ||
            formatDate(invoice.createdAt).lowercased().contains(searchTerm) ||
            invoice.id.uuidString.lowercased().contains(searchTerm) ||
            "\(invoice.amount)".contains(searchTerm)
    }
}


// MARK: - Preview
struct InvoiceListView_Previews: PreviewProvider {
    static var previews: some View {
        InvoiceListView()
    }
}

struct InvoiceRow: View {
    let invoice: Invoice

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(invoice.paymentType.rawValue.capitalized)
                    .font(.headline)

                Text("\(formatDate(invoice.createdAt)) #\(invoice.id.uuidString.prefix(8))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack {
                Text("₹ \(invoice.amount)")
                    .font(.headline)
                    .foregroundColor(AppConfig.buttonColor)

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy" // Customize the date format as needed
    return formatter.string(from: date)
}
