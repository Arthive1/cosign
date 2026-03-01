import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct CoSignHomeView: View {
    let isProfileComplete: Bool
    @Binding var mySignBalance: Int
    @Binding var showProfileSetup: Bool
    @Binding var showIncompleteAlert: Bool
    @Binding var isFinding: Bool
    @Binding var matchedUser: [String: Any]?
    @Binding var currentUserData: [String: Any]?
    @Binding var similarityScore: Double
    @Binding var showSendSignConfirm: Bool
    @Binding var isSignSent: Bool
    @Binding var sentSignUserIds: Set<String>
    @Binding var pendingUsers: [[String: Any]]
    
    // 이 뷰에서만 쓰는 함수들
    let fetchMyData: () -> Void
    let startMatchingProcess: () -> Void
    let generateMockUsers: () -> Void
    let isGeneratingData: Bool

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. My Sign 행 (Top)
                headerSection
                    .padding(.top, 10)
                
                Spacer()
                
                // 2. 중앙 영역: 매칭 전(버튼) vs 매칭 후(비교 UI)
                if let otherUser = matchedUser, let myData = currentUserData {
                    comparisonSection(myData: myData, otherData: otherUser)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale), removal: .opacity))
                } else {
                    findButtonSection
                }
                
                Spacer()
                
                // 3. 하단 풋터
                footerSection
            }
            
            // 4. Send Sign 확인 팝업 (Overlay)
            if showSendSignConfirm {
                sendSignConfirmationOverlay
            }
        }
    }
    
    // MARK: - Header (Profile & Sign)
    private var headerSection: some View {
        HStack {
            // 왼쪽: 프로필 영역
            HStack(spacing: 8) {
                if let profileUrl = currentUserData?["profileImageUrl"] as? String, !profileUrl.isEmpty {
                    AsyncImage(url: URL(string: profileUrl)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill").foregroundColor(.gray.opacity(0.3))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                Text("\(currentUserData?["lastName"] as? String ?? "")\(currentUserData?["firstName"] as? String ?? "")")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Note: showProfileMenu is in MainView, so we omit this here or pass it as binding
                // But simplified for now
                NotificationCenter.default.post(name: NSNotification.Name("ShowProfileMenu"), object: nil)
            }
            
            Spacer()
            
            // 오른쪽: Sign 잔액 영역
            HStack(spacing: 8) {
                Text("Sign")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(mySignBalance)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { mySignBalance += 100 }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: 60)
    }

    // MARK: - Footer (Mock Data / New Match)
    private var footerSection: some View {
        VStack(spacing: 12) {
            if matchedUser != nil {
                if !isSignSent {
                    Button(action: { showSendSignConfirm = true }) {
                        Text("Send Sign")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 5)
                } else {
                    Text("Co-sign Found!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                }
                
                Button(action: { 
                    withAnimation(.spring()) {
                        matchedUser = nil 
                        isSignSent = false
                    }
                }) {
                    Text("Find New Co-sign")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue.opacity(0.8))
                }
                .padding(.bottom, 5)
            }
            
            HStack(spacing: 40) {
                Button(action: { generateMockUsers() }) {
                    HStack {
                        if isGeneratingData { ProgressView().scaleEffect(0.7) }
                        else { Image(systemName: "database.fill") }
                        Text("Mock Data")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue.opacity(0.5))
                }
                .disabled(isGeneratingData)
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Find Button Section
    private var findButtonSection: some View {
        VStack {
            if !isProfileComplete {
                Button(action: { showProfileSetup = true }) {
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
                            .fill(Color(red: 1.0, green: 0.92, blue: 0.85))
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
            
            Button(action: {
                if isProfileComplete {
                    startMatchingProcess()
                } else {
                    showIncompleteAlert = true
                }
            }) {
                VStack(spacing: 20) {
                    if isFinding {
                        ProgressView().scaleEffect(1.5).padding()
                        Text("Calculating Similarity...")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.94))
                        Text("Find Co-sign")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                    }
                }
                .frame(width: 250, height: 250)
                .background(Color.white)
                .cornerRadius(40)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
            }
            .scaleEffect(isFinding ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isFinding)
            
            Text("Tap to find your Co-sign")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
    }
    
    // MARK: - Comparison UI
    private func comparisonSection(myData: [String: Any], otherData: [String: Any]) -> some View {
        VStack(spacing: 15) {
            Text(String(format: "Similarity Score: %.2f%%", similarityScore * 100))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.94))
                .padding(.top, 10)
            
            HStack(spacing: 0) {
                ProfileComparisonColumn(title: "Me", data: myData, isMatch: false, showPhoneNumber: isSignSent)
                ProfileComparisonColumn(title: "Co-sign", data: otherData, isMatch: true, showPhoneNumber: isSignSent)
            }
        }
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Send Sign Overlay
    private var sendSignConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showSendSignConfirm = false }
            
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
                    Button(action: { showSendSignConfirm = false }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 65)
                            .background(Color(white: 0.95))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        if mySignBalance >= 100 {
                            mySignBalance -= 100
                            isSignSent = true
                            if let other = matchedUser, let otherId = other["uid"] as? String {
                                sentSignUserIds.insert(otherId)
                                if !pendingUsers.contains(where: { ($0["uid"] as? String) == otherId }) {
                                    pendingUsers.append(other)
                                }
                            }
                            showSendSignConfirm = false
                        } else {
                            showSendSignConfirm = false
                        }
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
}
