import Foundation

class Playlist: ObservableObject {
    @Published var tracks: [Track]
    let title: String
    
    init(title: String, tracks: [Track] = []) {
        self.title = title
        self.tracks = tracks
    }
    
    func addTrack(_ track: Track) {
        if !tracks.contains(where: { $0.id == track.id }) {
            tracks.append(track)
        }
    }
    
    func removeTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
    }
} 