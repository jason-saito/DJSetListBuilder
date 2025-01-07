import Foundation

struct Track: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let bpm: Double
    let genre: String
    let artworkURL: String?
    let duration: Int
    let url: URL?
    
    init(id: String, title: String, artist: String, bpm: Double, genre: String, artworkURL: String?, duration: Int, url: URL?) {
        self.id = id
        self.title = title
        self.artist = artist
        self.bpm = bpm
        self.genre = genre
        self.artworkURL = artworkURL
        self.duration = duration
        self.url = url
    }
} 