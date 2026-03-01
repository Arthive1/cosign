import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatDetailView: View {
    let otherUser: [String: Any]
    @Environment(\.dismiss) var dismiss
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: UUID(), text: "Hello! I saw your Co-sign profile.", isMe: false),
        ChatMessage(id: UUID(), text: "Hi! Nice to meet you. We have a high similarity score!", isMe: true),
        ChatMessage(id: UUID(), text: "Yes! 92% is impressive. What are your hobbies?", isMe: false)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 네비게이션 바
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Spacer()
                
                Text("\(otherUser["lastName"] as? String ?? "")\(otherUser["firstName"] as? String ?? "")")
                    .font(.system(size: 17, weight: .bold))
                
                Spacer()
                
                HStack(spacing: 15) {
                    Image(systemName: "magnifyingglass")
                    Image(systemName: "line.3.horizontal")
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .foregroundColor(.primary)
            
            // 메시지 리스트
            ScrollView {
                VStack(spacing: 15) {
                    Text("March 1, 2026")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                    
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal, 15)
            }
            
            // 입력창
            HStack(spacing: 12) {
                Image(systemName: "plus.app")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                
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
    
    var body: some View {
        HStack {
            if message.isMe { Spacer() }
            
            Text(message.text)
                .font(.system(size: 15))
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(message.isMe ? Color(red: 0.53, green: 0.75, blue: 0.94) : Color(white: 0.94))
                .foregroundColor(message.isMe ? .white : .primary)
                .cornerRadius(18)
            
            if !message.isMe { Spacer() }
        }
    }
}

#Preview {
    ChatDetailView(otherUser: ["lastName": "Kim", "firstName": "Minsoo"])
}
