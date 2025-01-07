import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var soundCloudService: SoundCloudService
    @State private var searchText = ""
    @State private var selectedTracks: [Track] = []
    @State private var searchResults: [Track] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    let title: String
    let genre: String
    let bpmRange: ClosedRange<Double>
    
    var body: some View {
        VStack {
            TextField("Search tracks...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if isLoading {
                ProgressView("Searching...")
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                List {
                    ForEach(searchResults) { track in
                        TrackRow(track: track)
                            .swipeActions(edge: .leading) {
                                Button {
                                    if !selectedTracks.contains(where: { $0.id == track.id }) {
                                        selectedTracks.append(track)
                                    }
                                } label: {
                                    Label("Add", systemImage: "plus.circle")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                if selectedTracks.contains(where: { $0.id == track.id }) {
                                    Button(role: .destructive) {
                                        selectedTracks.removeAll { $0.id == track.id }
                                    } label: {
                                        Label("Remove", systemImage: "minus.circle")
                                    }
                                }
                            }
                            .listRowBackground(
                                selectedTracks.contains(where: { $0.id == track.id }) ?
                                Color(.systemGray6) : Color(.systemBackground)
                            )
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            if !selectedTracks.isEmpty {
                NavigationLink(destination: PlaylistView(
                    playlist: Playlist(title: title, tracks: selectedTracks),
                    title: title,
                    genre: genre,
                    bpmRange: bpmRange
                )) {
                    Text("Done (\(selectedTracks.count) tracks)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
        .navigationTitle("Add Tracks")
        .task {
            await search()
        }
        .onChange(of: searchText) { oldValue, newValue in
            Task {
                await search()
            }
        }
    }
    
    private func search() async {
        isLoading = true
        error = nil
        
        do {
            searchResults = try await soundCloudService.searchTracks(
                bpmRange: bpmRange,
                genre: genre
            )
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

struct TrackRow: View {
    let track: Track
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(track.title)
                .font(.headline)
            Text(track.artist)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Label("\(Int(track.bpm)) BPM", systemImage: "metronome")
                Spacer()
                Label(track.genre, systemImage: "music.note")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SearchView(
            title: "My Playlist",
            genre: "House",
            bpmRange: 120...130
        )
        .environmentObject(SoundCloudService())
    }
} 