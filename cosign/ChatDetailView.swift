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
    
    // 상대방이 나갔는지 여부 (Mock 데이터 기반)
    private var isUserLeft: Bool {
        return otherUser["hasLeft"] as? Bool ?? false
    }
    
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
                    
                    Button(action: { 
                        withAnimation {
                            isSearching.toggle()
                            if !isSearching { searchText = "" }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal, 15)
                
                // 중앙 닉네임
                Text("\(otherUser["lastName"] as? String ?? "")\(otherUser["firstName"] as? String ?? "")")
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
            
            // 입력창 (상대방이 나갔으면 비활성화)
            if !isUserLeft {
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
            } else {
                // 나갔을 때의 입력창 대체 UI
                Text("You cannot send messages to this user.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.98))
            }
        }
        .navigationBarHidden(true)
    }
    
    private func sendMessage() {
        let newMessage = ChatMessage(id: UUID(), text: messageText, isMe: true)
        messages.append(newMessage)
        messageText = ""
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
    ChatDetailView(otherUser: ["lastName": "Kim", "firstName": "Minsoo", "hasLeft": false])
}
