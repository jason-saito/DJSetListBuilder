import SwiftUI

struct CustomSetlistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var customTracks: [CustomTrack] = []
    @State private var showingAddTrack = false
    @State private var selectedGenre = "All"
    @State private var customGenre = ""
    @State private var isCustomGenre = false
    @State private var minBPM: Double = 120
    @State private var maxBPM: Double = 140
    @State private var shouldNavigateToHome = false
    @EnvironmentObject private var setListService: SetListService
    
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
            Text("New Custom Setlist")
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
            
            // Genre and BPM controls (same as CreateSetlistView)
            
            List {
                ForEach(customTracks) { track in
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(track.title)
                                    .font(.headline)
                                if !track.artist.isEmpty {
                                    Text(track.artist)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if let url = track.url {
                                Link(destination: url) {
                                    Image(systemName: "link.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                }
                            }
                        }
                        
                        HStack {
                            if track.bpm > 0 {
                                Label("\(Int(track.bpm)) BPM", systemImage: "metronome")
                            }
                            if !track.genre.isEmpty {
                                Label(track.genre, systemImage: "music.note")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    customTracks.remove(atOffsets: indexSet)
                }
            }
            
            Button {
                showingAddTrack = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Track")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(title.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .disabled(title.isEmpty)
            
            if !customTracks.isEmpty {
                Button {
                    saveSetList()
                } label: {
                    Text("Create Setlist")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(title.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(title.isEmpty)
            }
        }
        .sheet(isPresented: $showingAddTrack) {
            AddCustomTrackView { track in
                customTracks.append(track)
            }
        }
        .navigationDestination(isPresented: $shouldNavigateToHome) {
            HomeView()
        }
    }
    
    private func saveSetList() {
        let setList = SetList(
            title: title,
            genre: effectiveGenre,
            bpmRange: bpmRange,
            tracks: customTracks.map { $0.toTrack() },
            isCustom: true
        )
        setListService.addSetList(setList)
        shouldNavigateToHome = true
    }
}

struct CustomTrack: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let bpm: Double
    let genre: String
    let url: URL?
    
    func toTrack() -> Track {
        Track(
            id: id.uuidString,
            title: title,
            artist: artist,
            bpm: bpm,
            genre: genre,
            artworkURL: nil,
            duration: 0,
            url: url
        )
    }
}

struct AddCustomTrackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var artist = ""
    @State private var bpm = ""
    @State private var genre = ""
    @State private var urlString = ""
    
    let onAdd: (CustomTrack) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Song Name *", text: $title)
                TextField("Artist Name", text: $artist)
                TextField("BPM", text: $bpm)
                    .keyboardType(.numberPad)
                TextField("Genre", text: $genre)
                TextField("Song URL (optional)", text: $urlString)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            .navigationTitle("Add Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let track = CustomTrack(
                            title: title,
                            artist: artist,
                            bpm: Double(bpm) ?? 0,
                            genre: genre,
                            url: URL(string: urlString)
                        )
                        onAdd(track)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
} 