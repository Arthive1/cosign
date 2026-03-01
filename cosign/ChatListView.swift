import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatListView: View {
    @State private var matchedUsers: [[String: Any]] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 헤더
                HStack {
                    Text("Chats")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    HStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                        Image(systemName: "person.badge.plus")
                        Image(systemName: "music.note")
                        Image(systemName: "gearshape")
                    }
                    .font(.system(size: 20))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                // 탭 레이아웃 (Friends / News)
                HStack(spacing: 20) {
                    Text("Conversations")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.bottom, 8)
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .offset(y: 4),
                            alignment: .bottom
                        )
                    
                    Text("Channel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 리스트
                ScrollView {
                    VStack(spacing: 0) {
                        if isLoading {
                            ProgressView()
                                .padding(.top, 50)
                        } else if matchedUsers.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("No conversations yet.\nFind your Co-sign first!")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 100)
                        } else {
                            ForEach(0..<matchedUsers.count, id: \.self) { index in
                                NavigationLink(destination: ChatDetailView(otherUser: matchedUsers[index])) {
                                    ChatRow(user: matchedUsers[index])
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .background(Color.white)
            .onAppear {
                fetchMatchedUsers()
            }
        }
    }
    
    private func fetchMatchedUsers() {
        // 실제로는 나와 시그널을 주고받은 유저들을 가져와야 함
        // 현재는 Mock 데이터를 가져오거나 빈 리스트로 시작
        isLoading = true
        let db = Firestore.firestore()
        
        // 시뮬레이션을 위해 랜덤 유저 몇 명을 가져옴 (실제로는 매칭된 유저 필터링 필요)
        db.collection("users").limit(to: 5).getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                self.matchedUsers = docs.map { $0.data() }
            }
            isLoading = false
        }
    }
}

struct ChatRow: View {
    let user: [String: Any]
    
    var body: some View {
        HStack(spacing: 15) {
            // 프로필 이미지
            if let url = user["profileImageUrl"] as? String, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.1))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(user["lastName"] as? String ?? "")\(user["firstName"] as? String ?? "")")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Text("Just now")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(user["jobField"] as? String ?? "Co-sign matched!")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    ChatListView()
}
