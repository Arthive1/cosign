import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatListView: View {
    let currentUserData: [String: Any]?
    @Binding var mySignBalance: Int
    @Binding var pendingUsers: [[String: Any]]
    @Binding var receivedUsers: [[String: Any]]
    @Binding var sentSignUserIds: Set<String>
    
    @State private var matchedUsers: [[String: Any]] = []
    @State private var isLoading: Bool = true
    @State private var selectedMenu: Int = 0 // 0: Pending Signs, 1: Co-Sign
    @State private var showPendingDetail: Bool = false
    @State private var selectedPendingUser: [String: Any]? = nil
    @State private var selectedIsReceived: Bool = false
    
    // 취소/수락 관련 상태
    @State private var showCancelAlert: Bool = false
    @State private var showAcceptAlert: Bool = false
    @State private var showInsufficientSignsAlert: Bool = false
    @State private var userToProcess: [String: Any]? = nil
    
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
                    
                    // 메뉴 탭
                    HStack(spacing: 25) {
                        tabButton(title: "Pending Signs", tag: 0)
                        tabButton(title: "Co-Sign", tag: 1)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    if selectedMenu == 0 {
                        // 1. Pending Signs 섹션
                        if pendingUsers.isEmpty && receivedUsers.isEmpty {
                            emptyStateView(icon: "paperplane", text: "No pending signs.\nTry to find your Co-sign!")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                if !pendingUsers.isEmpty {
                                    Section(header: Text("Sign Sent").font(.system(size: 13, weight: .bold)).foregroundColor(.gray)) {
                                        ForEach(0..<pendingUsers.count, id: \.self) { index in
                                            PendingSignRow(me: currentUserData, other: pendingUsers[index], type: .sent)
                                                .listRowInsets(EdgeInsets())
                                                .listRowSeparator(.hidden)
                                                .onTapGesture {
                                                    selectedPendingUser = pendingUsers[index]
                                                    selectedIsReceived = false
                                                    showPendingDetail = true
                                                }
                                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                    Button(role: .destructive) {
                                                        userToProcess = pendingUsers[index]
                                                        showCancelAlert = true
                                                    } label: {
                                                        Label("Cancel", systemImage: "xmark.circle.fill")
                                                    }
                                                }
                                        }
                                    }
                                }
                                
                                if !receivedUsers.isEmpty {
                                    Section(header: Text("Sign Received").font(.system(size: 13, weight: .bold)).foregroundColor(.gray)) {
                                        ForEach(0..<receivedUsers.count, id: \.self) { index in
                                            PendingSignRow(me: currentUserData, other: receivedUsers[index], type: .received)
                                                .listRowInsets(EdgeInsets())
                                                .listRowSeparator(.hidden)
                                                .onTapGesture {
                                                    selectedPendingUser = receivedUsers[index]
                                                    selectedIsReceived = true
                                                    showPendingDetail = true
                                                }
                                        }
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            .background(Color.white)
                        }
                    } else {
                        // 2. Co-Sign 섹션
                        ScrollView {
                            VStack(spacing: 0) {
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
                                        
                                        if index < matchedUsers.count - 1 {
                                            Divider().padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 프로필 팝업 오버레이
                if showPendingDetail, let other = selectedPendingUser {
                    PendingProfileOverlay(
                        user: other, 
                        isShowing: $showPendingDetail,
                        isReceived: selectedIsReceived,
                        onSendSign: {
                            userToProcess = other
                            if mySignBalance >= 100 {
                                showAcceptAlert = true
                            } else {
                                showInsufficientSignsAlert = true
                            }
                        }
                    )
                }
                
                // 사인 전송 확인 커스텀 오버레이 (MainView와 동일한 디자인 및 표현)
                if showAcceptAlert {
                    sendSignConfirmationOverlay
                }
                
                // 사인 부족 알림 팝업 (MainView와 동일)
                if showInsufficientSignsAlert {
                    insufficientSignsOverlay
                }
            }
            .background(Color.white)
            .onAppear {
                fetchMatchedUsers()
            }
            // 취소 얼럿 (스와이프 시)
            .alert("Cancel Sign", isPresented: $showCancelAlert) {
                Button("Keep", role: .cancel) { }
                Button("Cancel Sign", role: .destructive) {
                    if let user = userToProcess, let uid = user["uid"] as? String {
                        pendingUsers.removeAll(where: { ($0["uid"] as? String) == uid })
                        sentSignUserIds.remove(uid)
                    }
                }
            } message: {
                Text("Are you sure you want to cancel sending a sign? 100 Signs will not be refunded.")
            }
        }
    }
    
    // MARK: - Send Sign Overlay (MainView와 동일하게 통일)
    private var sendSignConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showAcceptAlert = false }
            
            VStack(spacing: 25) {
                VStack(spacing: 12) {
                    Text("Would you like to send a Sign?")
                        .font(.system(size: 17, weight: .bold))
                    Text("100 Signs will be deducted\nif the other person also sends a Sign.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 10)
                
                HStack(spacing: 15) {
                    Button(action: { showAcceptAlert = false }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 65)
                            .background(Color(white: 0.95))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        acceptReceivedSign()
                        showAcceptAlert = false
                    }) {
                        Text("Send")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 65)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(25)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Insufficient Signs Overlay (MainView와 동일하게 통일)
    private var insufficientSignsOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showInsufficientSignsAlert = false }
            
            VStack(spacing: 25) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Insufficient Signs")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("You don't have enough signs.\nWould you like to top up?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 10)
                
                HStack(spacing: 15) {
                    Button(action: { showInsufficientSignsAlert = false }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color(white: 0.95))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        // 시뮬레이션: 충전 버튼 누르면 500개 추가
                        mySignBalance += 500
                        showInsufficientSignsAlert = false
                    }) {
                        Text("Top Up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(25)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
    
    private func acceptReceivedSign() {
        guard let user = userToProcess, let uid = user["uid"] as? String else { return }
        
        if mySignBalance >= 100 {
            mySignBalance -= 100
            
            // 1. 받은 목록에서 제거
            receivedUsers.removeAll(where: { ($0["uid"] as? String) == uid })
            
            // 2. 매칭 목록에 추가
            var newUser = user
            newUser["lastMessage"] = "Match established! Start chatting."
            matchedUsers.insert(newUser, at: 0) // 최상단에 추가
            
            // 3. 네비게이션 이동 (선택 사항: 코사인 탭으로 변경)
            withAnimation {
                selectedMenu = 1
                showPendingDetail = false
            }
        } else {
            // 사인이 부족한 경우에 대한 시나리오는 유지
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
    }
    
    private func fetchMatchedUsers() {
        if !matchedUsers.isEmpty { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users").limit(to: 2).getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                self.matchedUsers = docs.map { $0.data() }
            }
            isLoading = false
        }
    }
}

enum SignType {
    case sent, received
}

// MARK: - Pending Signs Row Component
struct PendingSignRow: View {
    let me: [String: Any]?
    let other: [String: Any]
    var type: SignType = .sent
    
    var body: some View {
        HStack(spacing: 15) {
            miniProfileCircle(userData: other)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(other["lastName"] as? String ?? "")\(other["firstName"] as? String ?? "")")
                    .font(.system(size: 16, weight: .bold))
                Text(type == .sent ? "Sent Sign" : "Received Sign")
                    .font(.system(size: 12))
                    .foregroundColor(type == .sent ? .secondary : Color(red: 0.53, green: 0.75, blue: 0.94))
            }
            
            Spacer()
            
            Text("Pending")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .contentShape(Rectangle())
    }
    
    private func miniProfileCircle(userData: [String: Any]?) -> some View {
        Group {
            if let url = userData?["profileImageUrl"] as? String, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.1))
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
}

// MARK: - Pending Profile Overlay
struct PendingProfileOverlay: View {
    let user: [String: Any]
    @Binding var isShowing: Bool
    var isReceived: Bool = false
    var onSendSign: () -> Void = {}
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { isShowing = false }
            
            VStack {
                ProfileComparisonColumn(title: "Profile Detail", data: user, isMatch: true)
                    .padding(.horizontal, 10)
                
                HStack(spacing: 15) {
                    // Close 버튼 (왼쪽)
                    Button(action: { isShowing = false }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.95))
                            .cornerRadius(12)
                    }
                    
                    // 받은 사인인 경우 Send Sign 버튼 표시 (오른쪽)
                    if isReceived {
                        Button(action: {
                            isShowing = false
                            onSendSign()
                        }) {
                            Text("Send Sign")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 25)
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
            if let url = user["profileImageUrl"] as? String, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
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
                
                Text(user["lastMessage"] as? String ?? (user["jobField"] as? String ?? "New Message"))
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
    ChatListView(
        currentUserData: nil, 
        mySignBalance: .constant(500),
        pendingUsers: .constant([]), 
        receivedUsers: .constant([]), 
        sentSignUserIds: .constant([])
    )
}
