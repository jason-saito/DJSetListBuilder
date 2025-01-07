import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var setListService: SetListService
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Welcome Back!")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            NavigationLink(destination: CreateSetlistView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New Setlist")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            if setListService.setlists.isEmpty {
                Spacer()
                Text("No setlists yet")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                Text("Previous Setlists")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(setListService.setlists) { setlist in
                            SetlistCard(setlist: setlist)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            setListService.deleteSetList(setlist)
                                        }
                                    } label: {
                                        Label("Delete Setlist", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct SetlistCard: View {
    let setlist: SetList
    
    var body: some View {
        NavigationLink(destination: PlaylistView(
            playlist: Playlist(title: setlist.title, tracks: setlist.tracks),
            title: setlist.title,
            genre: setlist.genre,
            bpmRange: setlist.bpmRange,
            existingSetList: setlist
        )) {
            VStack(alignment: .leading, spacing: 8) {
                Text(setlist.title)
                    .font(.headline)
                
                HStack {
                    Label(setlist.genre, systemImage: "music.note")
                    Spacer()
                    Label("\(setlist.tracks.count) songs", systemImage: "music.note.list")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Text("BPM: \(Int(setlist.bpmRange.lowerBound))-\(Int(setlist.bpmRange.upperBound))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(SetListService())
    }
} 