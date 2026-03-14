import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatDetailView: View {
    let otherUser: [String: Any]
    @Environment(\.dismiss) var dismiss
    @State private var messageText: String = ""
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: UUID(), text: "Hello! I saw your Co-sign profile.", isMe: false),
        ChatMessage(id: UUID(), text: "Hi! Nice to meet you. We have a high similarity score!", isMe: true),
        ChatMessage(id: UUID(), text: "Yes! 92% is impressive. What are your hobbies?", isMe: false)
    ]
    
    // 차단 및 신고 팝업 상태
    @State private var showBlockAlert: Bool = false
    @State private var showReportAlert: Bool = false
    @State private var showReportCompleteAlert: Bool = false
    
    // 마지막 메시지 업데이트를 위한 콜백
    var onMessageSent: ((String) -> Void)? = nil
    
    // 상대방이 나갔는지 여부 (Mock 데이터 기반)
    private var isUserLeft: Bool {
        return otherUser["hasLeft"] as? Bool ?? false
    }
    
    // 이 채팅방이 차단된 상태인지 판단 (로컬 혹은 상위 UI에서 주입됨)
    // 원칙적으로는 두 유저 중 한 명이라도 blockedUsers에 상대가 있으면 true
    @State private var isBlocked: Bool = false
    
    // 검색 필터링된 메시지
    private var filteredMessages: [ChatMessage] {
        if searchText.isEmpty {
            return messages
        } else {
            return messages.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 네비게이션 바
            ZStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: { 
                            withAnimation {
                                isSearching.toggle()
                                if !isSearching { searchText = "" }
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                        }
                        
                        // 차단 / 신고 메뉴
                        Menu {
                            Button(role: .destructive, action: { showBlockAlert = true }) {
                                Label("Block User", systemImage: "nosign")
                            }
                            Button(role: .destructive, action: { showReportAlert = true }) {
                                Label("Report User", systemImage: "exclamationmark.bubble")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20))
                                .rotationEffect(.degrees(90))
                        }
                    }
                    .foregroundColor(.primary)
                }
                .padding(.horizontal, 15)
                
                // 중앙 닉네임
                Text("\(otherUser["nickname"] as? String ?? "User")")
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(height: 50)
            .foregroundColor(.primary)
            
            // 검색바 (활성화 시 표시)
            if isSearching {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search messages...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(white: 0.95))
                .cornerRadius(10)
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
            
            Divider()
            
            // 메시지 리스트
            ScrollView {
                VStack(spacing: 20) {
                    Text("March 1, 2026")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                    
                    ForEach(filteredMessages) { message in
                        MessageBubble(message: message, otherUser: otherUser)
                    }
                    
                    // 상대방이 나갔을 때 알림 UI
                    if isUserLeft {
                        VStack(spacing: 5) {
                            Divider()
                                .padding(.vertical, 10)
                            
                            Text("\(otherUser["lastName"] as? String ?? "")\(otherUser["firstName"] as? String ?? "") has left the chat.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 20)
            }
            
            // 입력창 (상대방이 나갔거나, 차단되었으면 비활성화)
            if isBlocked {
                // 차단되었을 때의 입력창 대체 UI
                Text("Messaging has been blocked.")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.98))
            } else if isUserLeft {
                // 나갔을 때의 입력창 대체 UI
                Text("You cannot send messages to this user.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.98))
            } else {
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.96))
                        .cornerRadius(20)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(messageText.isEmpty ? .gray.opacity(0.3) : .blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color.white)
            }
        }
        .navigationBarHidden(true)
        .alert("Block User", isPresented: $showBlockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                blockUser()
            }
        } message: {
            Text("Are you sure you want to block this user? They will no longer be able to message you.")
        }
        .alert("Report User", isPresented: $showReportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Report", role: .destructive) {
                reportUser()
            }
        } message: {
            Text("Please report if this user violates our guidelines. The administrative team will review it within 24 hours.")
        }
        .alert("Report Submitted", isPresented: $showReportCompleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your report has been received and will be reviewed within 24 hours.")
        }
    }
    
    private func sendMessage() {
        if messageText.trimmingCharacters(in: .whitespaces).isEmpty { return }
        let newMessage = ChatMessage(id: UUID(), text: messageText, isMe: true)
        messages.append(newMessage)
        onMessageSent?(messageText) // 목록 화면으로 마지막 메시지 전달
        messageText = ""
    }
    
    // MARK: - Block & Report Logic
    private func blockUser() {
        guard let myUid = Auth.auth().currentUser?.uid,
              let targetUid = otherUser["uid"] as? String else { 
            // Mock data 처리 또는 uid가 없을 때 화면 내장 반영을 위해 dismiss 대신 isBlocked = true
            withAnimation {
                isBlocked = true
            }
            return 
        }
        
        Firestore.firestore().collection("users").document(myUid).updateData([
            "blockedUsers": FieldValue.arrayUnion([targetUid])
        ]) { error in
            if let error = error {
                print("Error blocking user: \(error.localizedDescription)")
            } else {
                // 차단 성공 시 화면 안에서 즉시 차단 상태로 변경 (대화창 비활성화)
                withAnimation {
                    isBlocked = true
                }
            }
            // 기존에는 dismiss()로 바로 나갔으나, 이제 화면 내장 반영을 위해 나가지 않게 함 (원할 경우 추가 가능)
        }
    }
    
    private func reportUser() {
        guard let myUid = Auth.auth().currentUser?.uid,
              let targetUid = otherUser["uid"] as? String else {
            showReportCompleteAlert = true
            return
        }
        
        let reportData: [String: Any] = [
            "reporterId": myUid,
            "reportedId": targetUid,
            "timestamp": FieldValue.serverTimestamp(),
            "reason": "User reported from ChatDetailView"
        ]
        
        Firestore.firestore().collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                print("Error reporting user: \(error.localizedDescription)")
            } else {
                showReportCompleteAlert = true
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isMe: Bool
}

struct MessageBubble: View {
    let message: ChatMessage
    let otherUser: [String: Any]
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isMe {
                Spacer()
            } else {
                // 상대방 프로필 사진
                miniProfileCircle(userData: otherUser)
            }
            
            Text(message.text)
                .font(.system(size: 15))
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(message.isMe ? Color(red: 0.53, green: 0.75, blue: 0.94) : Color(white: 0.94))
                .foregroundColor(message.isMe ? .white : .primary)
                .cornerRadius(18)
            
            if !message.isMe {
                Spacer()
            }
        }
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
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
}

#Preview {
    ChatDetailView(otherUser: ["lastName": "Kim", "firstName": "Minsoo", "hasLeft": false], onMessageSent: { _ in })
}
