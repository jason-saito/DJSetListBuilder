import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject private var setListService: SetListService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isEditingTitle = false
    @State private var editedTitle: String
    @State private var shouldNavigateToHome = false
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
            
            List {
                ForEach(playlist.tracks) { track in
                    HStack {
                        TrackRow(track: track)
                        if let url = track.url {
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
                }
            }
            .listStyle(PlainListStyle())
            
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
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToHome) {
            HomeView()
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