import SwiftUI
import Firebase
import FirebaseAuth

struct MainView: View {
    @State private var isFinding: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경
                Color(white: 0.98)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // 핵심 기능: Find Co-sign 버튼
                    Button(action: {
                        isFinding = true
                        // 여기에 나중에 코사인 유사도 로직이 들어갈 예정입니다.
                        print("Finding similar users...")
                    }) {
                        VStack(spacing: 20) {
                            Image(systemName: "person.2.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.94))
                            
                            Text("Find Co-sign")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        }
                        .frame(width: 280, height: 280)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color(red: 0.67, green: 0.82, blue: 0.94).opacity(0.3), lineWidth: 2)
                        )
                    }
                    .scaleEffect(isFinding ? 0.95 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isFinding)
                    
                    Text("탭하여 가장 유사한 사람을 찾아보세요")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 25)
                    
                    Spacer()
                    
                    // 로그아웃 버튼 (하단에 작게 배치)
                    Button(action: {
                        try? Auth.auth().signOut()
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Main")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden) // 메인의 깔끔한 디자인을 위해 툴바 숨김
        }
    }
}

#Preview {
    MainView()
}
