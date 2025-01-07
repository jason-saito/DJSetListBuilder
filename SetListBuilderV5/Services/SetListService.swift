import Foundation

@MainActor
class SetListService: ObservableObject {
    @Published private(set) var setlists: [SetList] = []
    private let saveKey = "saved_setlists"
    
    init() {
        loadSetlists()
    }
    
    func addSetList(_ setlist: SetList) {
        setlists.insert(setlist, at: 0) // Add new setlist at the beginning
        saveSetlists()
    }
    
    func updateSetList(_ setlist: SetList) {
        if let index = setlists.firstIndex(where: { $0.id == setlist.id }) {
            setlists[index] = setlist
            saveSetlists()
        }
    }
    
    func deleteSetList(_ setlist: SetList) {
        setlists.removeAll { $0.id == setlist.id }
        saveSetlists()
    }
    
    private func loadSetlists() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([SetList].self, from: data) {
            setlists = decoded
        }
    }
    
    private func saveSetlists() {
        if let encoded = try? JSONEncoder().encode(setlists) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
} 