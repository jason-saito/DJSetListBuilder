import Foundation

struct SetList: Identifiable, Codable {
    let id: UUID
    let title: String
    let genre: String
    private let bpmLower: Double
    private let bpmUpper: Double
    let tracks: [Track]
    
    var bpmRange: ClosedRange<Double> {
        bpmLower...bpmUpper
    }
    
    var songCount: Int {
        tracks.count
    }
    
    init(title: String, genre: String, bpmRange: ClosedRange<Double>, tracks: [Track]) {
        self.id = UUID()
        self.title = title
        self.genre = genre
        self.bpmLower = bpmRange.lowerBound
        self.bpmUpper = bpmRange.upperBound
        self.tracks = tracks
    }
    
    init(id: UUID, title: String, genre: String, bpmRange: ClosedRange<Double>, tracks: [Track]) {
        self.id = id
        self.title = title
        self.genre = genre
        self.bpmLower = bpmRange.lowerBound
        self.bpmUpper = bpmRange.upperBound
        self.tracks = tracks
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, genre, bpmLower, bpmUpper, tracks
    }
} 