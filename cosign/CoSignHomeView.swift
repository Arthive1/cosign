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
    
    @State private var showInsufficientSignsAlert: Bool = false
    @State private var showBalance: Bool = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
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
            
            // 5. 사인 부족 알림 팝업
            if showInsufficientSignsAlert {
                insufficientSignsOverlay
            }
        }
    }
    
    
    // MARK: - Footer (Mock Data / New Match)
    private var footerSection: some View {
        VStack(spacing: 12) {
            if matchedUser != nil {
                if !isSignSent {
                    Button(action: { 
                        if mySignBalance >= 100 {
                            showSendSignConfirm = true 
                        } else {
                            showInsufficientSignsAlert = true
                        }
                    }) {
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
                    Text("Sign Sent!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                }
                
                Button(action: { 
                    withAnimation {
                        matchedUser = nil // 프로필을 사라지게 하여 탐색 모션(findButtonSection)이 보이도록 함
                        isSignSent = false
                        startMatchingProcess() // 즉시 다음 매칭 시작
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
                        // 깔끔한 톱니바퀴(스피너) 모션과 영어 안내 문구
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.53, green: 0.75, blue: 0.94)))
                                .scaleEffect(1.8)
                            
                            Text("We are looking for the\nbest match for you...")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
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
            
            if !isFinding {
                Text("Tap to find your Co-sign")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
            }
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
                ProfileComparisonColumn(title: "Me", data: myData, isMatch: false)
                ProfileComparisonColumn(title: "Co-sign", data: otherData, isMatch: true)
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
                        Text("Cancel")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 65)
                            .background(Color(white: 0.95))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        if mySignBalance >= 100 {
                            // mySignBalance -= 100 // Remove immediate deduction
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
                            showInsufficientSignsAlert = true
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
    
    // MARK: - Insufficient Signs Overlay
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
                        Text("Cancel")
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
}
