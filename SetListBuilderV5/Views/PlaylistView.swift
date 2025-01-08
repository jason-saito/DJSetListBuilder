import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject private var setListService: SetListService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isEditingTitle = false
    @State private var editedTitle: String
    @State private var shouldNavigateToHome = false
    @State private var isEditingTracks = false
    @State private var showingAddTracksSheet = false
    @State private var tracksToRemove: Set<String> = []
    
    let playlist: Playlist
    let title: String
    let genre: String
    let bpmRange: ClosedRange<Double>
    let existingSetList: SetList?
    
    init(playlist: Playlist, title: String, genre: String, bpmRange: ClosedRange<Double>, existingSetList: SetList? = nil) {
        self.playlist = playlist
        self.title = title
        self.genre = genre
        self.bpmRange = bpmRange
        self.existingSetList = existingSetList
        _editedTitle = State(initialValue: title)
    }
    
    var body: some View {
        VStack {
            if isEditingTitle {
                TextField("Playlist Title", text: $editedTitle)
                    .font(.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        isEditingTitle = false
                    }
            } else {
                Text(editedTitle)
                    .font(.title)
                    .padding()
                    .onTapGesture {
                        isEditingTitle = true
                    }
            }
            
            if isEditingTracks {
                Button {
                    showingAddTracksSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to this Setlist")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            List {
                ForEach(playlist.tracks) { track in
                    HStack {
                        TrackRow(track: track, isSelected: false)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isEditingTracks {
                                    withAnimation {
                                        toggleTrackSelection(track.id)
                                    }
                                }
                            }
                        
                        if isEditingTracks {
                            Button {
                                withAnimation {
                                    toggleTrackSelection(track.id)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(tracksToRemove.contains(track.id) ? .red : .gray)
                                    .font(.title2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else if let url = track.url {
                            Button {
                                openURL(url)
                            } label: {
                                Image(systemName: "link.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listRowBackground(
                        isEditingTracks && tracksToRemove.contains(track.id) ?
                            Color.red.opacity(0.2) :
                            Color(.systemBackground)
                    )
                }
            }
            .listStyle(PlainListStyle())
            
            if isEditingTracks {
                HStack {
                    Button {
                        withAnimation {
                            tracksToRemove.removeAll()
                            isEditingTracks = false
                        }
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        withAnimation {
                            playlist.tracks.removeAll { tracksToRemove.contains($0.id) }
                            tracksToRemove.removeAll()
                            isEditingTracks = false
                        }
                    } label: {
                        Text("Confirm")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                Button {
                    withAnimation {
                        isEditingTracks = true
                    }
                } label: {
                    Text("Edit Tracks")
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToHome) {
            HomeView()
        }
        .sheet(isPresented: $showingAddTracksSheet) {
            NavigationStack {
                SearchView(
                    title: editedTitle,
                    genre: genre,
                    bpmRange: bpmRange,
                    initialTracks: playlist.tracks,
                    onDone: { tracks in
                        playlist.tracks = tracks
                        showingAddTracksSheet = false
                    }
                )
            }
        }
        .toolbar {
            if !isEditingTracks {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let updatedSetList = SetList(
                            id: existingSetList?.id ?? UUID(),
                            title: editedTitle,
                            genre: genre,
                            bpmRange: bpmRange,
                            tracks: playlist.tracks
                        )
                        
                        if existingSetList != nil {
                            setListService.updateSetList(updatedSetList)
                        } else {
                            setListService.addSetList(updatedSetList)
                        }
                        shouldNavigateToHome = true
                    } label: {
                        Text("Save")
                            .bold()
                    }
                }
            }
        }
    }
    
    private func toggleTrackSelection(_ trackId: String) {
        if tracksToRemove.contains(trackId) {
            tracksToRemove.remove(trackId)
        } else {
            tracksToRemove.insert(trackId)
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistView(
            playlist: Playlist(title: "Test Playlist", tracks: []),
            title: "Test Playlist",
            genre: "House",
            bpmRange: 120...130
        )
        .environmentObject(SetListService())
    }
} 