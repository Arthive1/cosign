import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 그라데이션
                LinearGradient(gradient: Gradient(colors: [Color(white: 0.98), Color(white: 0.95)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 60) {
                    Spacer()
                    
                    // 중앙 문구 섹션
                    VStack(spacing: 16) {
                        Text("Co-sign")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                            .tracking(1)
                        
                        Text("Find someone most like you")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 버튼 섹션
                    VStack(spacing: 16) {
                        // Sign in 버튼
                        Button(action: {
                            print("Sign in tapped")
                        }) {
                            Text("Sign in")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.67, green: 0.82, blue: 0.94))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                        }
                        
                        // Sign up 버튼 (Navigation 추가)
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.96, green: 0.76, blue: 0.76))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
