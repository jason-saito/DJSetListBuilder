import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var setListService: SetListService
    @State private var showingCreateOptions = false
    @State private var navigationPath = NavigationPath()
    
    enum NavigationType: Hashable {
        case soundCloud
        case custom
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 20) {
                HStack {
                    Text("Welcome Back!")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                Button {
                    showingCreateOptions = true
                } label: {
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
            .sheet(isPresented: $showingCreateOptions) {
                CreateOptionsView { flow in
                    showingCreateOptions = false
                    switch flow {
                    case .soundCloud:
                        navigationPath.append(NavigationType.soundCloud)
                    case .custom:
                        navigationPath.append(NavigationType.custom)
                    }
                }
                .presentationDetents([.medium])
                .presentationContentInteraction(.scrolls)
                .presentationBackground(.regularMaterial)
            }
            .navigationDestination(for: NavigationType.self) { type in
                switch type {
                case .soundCloud:
                    CreateSetlistView()
                case .custom:
                    CustomSetlistView()
                }
            }
            .navigationBarBackButtonHidden(true)
        }
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

struct CreateOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (CreationFlow) -> Void
    
    enum CreationFlow {
        case soundCloud
        case custom
    }
    
    var body: some View {
        ZStack {
            Color.clear
            
            VStack(spacing: 20) {
                Text("Choose Creation Method")
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 15) {
                    Button {
                        onSelect(.soundCloud)
                    } label: {
                        VStack {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 30))
                            Text("Create with\nSoundCloud")
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button {
                        onSelect(.custom)
                    } label: {
                        VStack {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 30))
                            Text("Create with\nCustom Input")
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(SetListService())
    }
} 