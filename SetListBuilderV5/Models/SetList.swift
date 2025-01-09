import Foundation

struct SetList: Identifiable, Codable {
    let id: UUID
    let title: String
    let genre: String
    let bpmRange: ClosedRange<Double>
    let tracks: [Track]
    let isCustom: Bool
    
    init(id: UUID = UUID(), title: String, genre: String, bpmRange: ClosedRange<Double>, tracks: [Track], isCustom: Bool = false) {
        self.id = id
        self.title = title
        self.genre = genre
        self.bpmRange = bpmRange
        self.tracks = tracks
        self.isCustom = isCustom
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, genre, bpmRange, tracks, isCustom
    }
} 