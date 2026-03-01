import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatListView: View {
    let currentUserData: [String: Any]?
    let pendingUsers: [[String: Any]]
    
    @State private var matchedUsers: [[String: Any]] = []
    @State private var isLoading: Bool = true
    @State private var selectedMenu: Int = 0 // 0: Pending Signs, 1: Co-Sign
    @State private var showPendingDetail: Bool = false
    @State private var selectedPendingUser: [String: Any]? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                    
                    // 메뉴 탭 (Pending Signs / Co-Sign)
                    HStack(spacing: 25) {
                        tabButton(title: "Pending Signs", tag: 0)
                        tabButton(title: "Co-Sign", tag: 1)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // 리스트
                    ScrollView {
                        VStack(spacing: 0) {
                            if selectedMenu == 0 {
                                // 1. Pending Signs 섹션
                                if !pendingUsers.isEmpty {
                                    ForEach(0..<pendingUsers.count, id: \.self) { index in
                                        PendingSignRow(me: currentUserData, other: pendingUsers[index])
                                            .onTapGesture {
                                                selectedPendingUser = pendingUsers[index]
                                                showPendingDetail = true
                                            }
                                        
                                        if index < pendingUsers.count - 1 {
                                            Divider().padding(.horizontal, 20)
                                        }
                                    }
                                } else {
                                    emptyStateView(icon: "paperplane", text: "No pending signs.\nTry to find your Co-sign!")
                                }
                            } else {
                                // 2. Co-Sign 섹션 (채팅)
                                if isLoading {
                                    ProgressView().padding(.top, 50)
                                } else if matchedUsers.isEmpty {
                                    emptyStateView(icon: "bubble.left.and.bubble.right", text: "No active chats.\nBoth sides must send signs!")
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
                }
                
                // 프로필 팝업 오버레이
                if showPendingDetail, let other = selectedPendingUser {
                    PendingProfileOverlay(user: other, isShowing: $showPendingDetail)
                }
            }
            .background(Color.white)
            .onAppear {
                fetchMatchedUsers()
            }
        }
    }
    
    private func tabButton(title: String, tag: Int) -> some View {
        Button(action: { selectedMenu = tag }) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: selectedMenu == tag ? .bold : .medium))
                    .foregroundColor(selectedMenu == tag ? .primary : .secondary)
                
                if selectedMenu == tag {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.primary)
                } else {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.clear)
                }
            }
        }
    }
    
    private func emptyStateView(icon: String, text: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(.top, 100)
    }
    
    private func fetchMatchedUsers() {
        isLoading = true
        let db = Firestore.firestore()
        
        // 시뮬레이션을 위해 유저 몇 명을 가져옴 (실제로는 상호 동의된 유저들)
        db.collection("users").limit(to: 3).getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                self.matchedUsers = docs.map { $0.data() }
            }
            isLoading = false
        }
    }
}

// MARK: - Pending Signs Row Component
struct PendingSignRow: View {
    let me: [String: Any]?
    let other: [String: Any]
    
    var body: some View {
        HStack(spacing: 12) {
            // My Profile
            miniProfileCircle(userData: me)
            
            // Me Name
            Text("\(me?["lastName"] as? String ?? "")\(me?["firstName"] as? String ?? "Me")")
                .font(.system(size: 14, weight: .bold))
            
            // Sign Icon
            Image(systemName: "waveform")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.94))
                .padding(.horizontal, 4)
            
            // Other Name
            Text("\(other["lastName"] as? String ?? "")\(other["firstName"] as? String ?? "")")
                .font(.system(size: 14, weight: .bold))
            
            // Other Profile
            miniProfileCircle(userData: other)
            
            Spacer()
            
            Text("Pending")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
        .contentShape(Rectangle())
    }
    
    private func miniProfileCircle(userData: [String: Any]?) -> some View {
        Group {
            if let url = userData?["profileImageUrl"] as? String, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.1))
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
}

// MARK: - Pending Profile Overlay
struct PendingProfileOverlay: View {
    let user: [String: Any]
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { isShowing = false }
            
            VStack {
                ProfileComparisonColumn(title: "Sent Sign To", data: user, isMatch: true, showPhoneNumber: false)
                    .padding(.horizontal, 10)
                
                Button(action: { isShowing = false }) {
                    Text("Close")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 25)
                        .padding(.bottom, 25)
                }
            }
            .background(Color.white)
            .cornerRadius(25)
            .padding(.horizontal, 30)
            .shadow(radius: 20)
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
                
                Text(user["jobField"] as? String ?? "New Message")
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
    ChatListView(currentUserData: nil, pendingUsers: [])
}
