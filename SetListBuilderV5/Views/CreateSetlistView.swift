import SwiftUI

struct CreateSetlistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedGenre = "All"
    @State private var customGenre = ""
    @State private var isCustomGenre = false
    @State private var minBPM: Double = 120
    @State private var maxBPM: Double = 140
    
    let genres = ["All", "House", "Hip-Hop", "Drum & Bass", "Techno", "Pop"]
    
    var bpmRange: ClosedRange<Double> {
        let lower = min(minBPM, maxBPM)
        let upper = max(minBPM, maxBPM)
        return lower...upper
    }
    
    var effectiveGenre: String {
        isCustomGenre ? customGenre : selectedGenre
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("New Setlist")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Title *")
                    .font(.headline)
                TextField("Enter title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Genre")
                    .font(.headline)
                
                Toggle("Custom Genre", isOn: $isCustomGenre)
                    .padding(.horizontal)
                
                if isCustomGenre {
                    TextField("Enter custom genre", text: $customGenre)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                } else {
                    Picker("Genre", selection: $selectedGenre) {
                        ForEach(genres, id: \.self) { genre in
                            Text(genre)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("BPM Range")
                    .font(.headline)
                HStack {
                    Text("Min: \(Int(minBPM))")
                    Slider(value: Binding(
                        get: { minBPM },
                        set: { newValue in
                            minBPM = newValue
                            if minBPM > maxBPM {
                                maxBPM = minBPM
                            }
                        }
                    ), in: 60...200)
                }
                HStack {
                    Text("Max: \(Int(maxBPM))")
                    Slider(value: Binding(
                        get: { maxBPM },
                        set: { newValue in
                            maxBPM = newValue
                            if maxBPM < minBPM {
                                minBPM = maxBPM
                            }
                        }
                    ), in: 60...200)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            NavigationLink(destination: SearchView(
                title: title,
                genre: effectiveGenre,
                bpmRange: bpmRange
            )) {
                Text("Create")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(title.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .disabled(title.isEmpty)
            .padding(.bottom)
        }
    }
}

#Preview {
    NavigationStack {
        CreateSetlistView()
    }
} 