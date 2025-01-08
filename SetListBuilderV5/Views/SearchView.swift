import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var soundCloudService: SoundCloudService
    @EnvironmentObject private var setListService: SetListService
    @State private var searchText = ""
    @State private var selectedTracks: [Track]
    @State private var searchResults: [Track] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var shouldNavigateToHome = false
    
    let title: String
    let genre: String
    let bpmRange: ClosedRange<Double>
    
    var onDone: (([Track]) -> Void)?
    
    init(title: String, genre: String, bpmRange: ClosedRange<Double>, initialTracks: [Track] = [], onDone: (([Track]) -> Void)? = nil) {
        self.title = title
        self.genre = genre
        self.bpmRange = bpmRange
        _selectedTracks = State(initialValue: initialTracks)
        self.onDone = onDone
    }
    
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
                        TrackRow(track: track, isSelected: selectedTracks.contains(where: { $0.id == track.id }))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    toggleTrackSelection(track)
                                }
                            }
                            .contextMenu {
                                if selectedTracks.contains(where: { $0.id == track.id }) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            selectedTracks.removeAll { $0.id == track.id }
                                        }
                                    } label: {
                                        Label("Remove from Setlist", systemImage: "minus.circle")
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
                if let onDone = onDone {
                    Button {
                        onDone(selectedTracks)
                    } label: {
                        Text("Done (\(selectedTracks.count) tracks)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding()
                    }
                } else {
                    Button {
                        let setList = SetList(
                            id: UUID(),
                            title: title,
                            genre: genre,
                            bpmRange: bpmRange,
                            tracks: selectedTracks
                        )
                        setListService.addSetList(setList)
                        shouldNavigateToHome = true
                    } label: {
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
        }
        .navigationTitle("Add Tracks")
        .navigationDestination(isPresented: $shouldNavigateToHome) {
            HomeView()
        }
        .task {
            await search()
        }
        .onChange(of: searchText) { oldValue, newValue in
            Task {
                await search()
            }
        }
    }
    
    private func toggleTrackSelection(_ track: Track) {
        if selectedTracks.contains(where: { $0.id == track.id }) {
            selectedTracks.removeAll { $0.id == track.id }
        } else {
            selectedTracks.append(track)
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
    let isSelected: Bool
    
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
        .environmentObject(SetListService())
    }
} 
