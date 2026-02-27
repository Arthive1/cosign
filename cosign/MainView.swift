import SwiftUI
import Firebase
import FirebaseAuth

struct MainView: View {
    let isProfileComplete: Bool
    @State private var isFinding: Bool = false
    @State private var showProfileSetup: Bool = false
    @State private var showIncompleteAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경
                Color(white: 0.98)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 프로필 업데이트 권장 박스 (미완료 시에만 표시)
                    if !isProfileComplete {
                        Button(action: {
                            showProfileSetup = true
                        }) {
                            VStack(spacing: 8) {
                                Text("Update Profiles")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                                
                                Text("The more detailed your profile,\nthe better your matches will be.")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 25)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color(red: 1.0, green: 0.92, blue: 0.85)) // 주황 파스텔톤
                                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(red: 0.95, green: 0.60, blue: 0.40).opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 30)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // 핵심 기능: Find Co-sign 버튼
                    Button(action: {
                        if isProfileComplete {
                            isFinding = true
                            print("Finding similar users...")
                        } else {
                            showIncompleteAlert = true
                        }
                    }) {
                        VStack(spacing: 20) {
                            Image(systemName: "person.2.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.94))
                            
                            Text("Find Co-sign")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        }
                        .frame(width: 250, height: 250)
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
                    
                    Text("Tap to find your Co-sign")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 로그아웃 버튼
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
            .toolbar(.hidden)
            .sheet(isPresented: $showProfileSetup) {
                ProfileSetupView()
            }
            .alert("Profile Incomplete", isPresented: $showIncompleteAlert) {
                Button("Update Profile") {
                    showProfileSetup = true
                }
                Button("Later", role: .cancel) { }
            } message: {
                Text("Please update your profile first to use this feature.")
            }
        }
    }
}

#Preview {
    MainView(isProfileComplete: false)
}
