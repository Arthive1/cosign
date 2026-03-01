import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    let isProfileComplete: Bool
    @State private var isFinding: Bool = false
    @State private var showProfileSetup: Bool = false
    @State private var showIncompleteAlert: Bool = false
    @AppStorage("mySignBalance") private var mySignBalance: Int = 0
    @State private var isGeneratingData: Bool = false
    
    // 매칭 관련 상태
    @State private var matchedUser: [String: Any]? = nil
    @State private var currentUserData: [String: Any]? = nil
    @State private var similarityScore: Double = 0.0
    @State private var showSendSignConfirm: Bool = false
    @State private var isSignSent: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.98).ignoresSafeArea()
                
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
                    
                    // 3. 로그아웃 행 (Bottom)
                    footerSection
                }
                
                // 4. Send Sign 확인 팝업 (Overlay)
                if showSendSignConfirm {
                    sendSignConfirmationOverlay
                }
            }
            .navigationTitle("Main")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden)
            .sheet(isPresented: $showProfileSetup) {
                ProfileSetupView()
            }
            .onAppear {
                fetchMyData()
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
    
    // MARK: - Header (My Sign)
    private var headerSection: some View {
        GeometryReader { geo in
            ZStack {
                Text("My Sign")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .position(x: geo.size.width / 3, y: geo.size.height / 2)
                
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
                .position(x: geo.size.width * 2 / 3, y: geo.size.height / 2)
            }
        }
        .frame(height: 40)
    }
    
    // MARK: - Footer (Mock Data / Sign Out)
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
                    Text("Sign Sent!")
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
                
                Button(action: { try? Auth.auth().signOut() }) {
                    Text("Log Out")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Find Button Section
    private var findButtonSection: some View {
        VStack {
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
            
            Button(action: {
                if isProfileComplete {
                    startMatchingProcess()
                } else {
                    showIncompleteAlert = true
                }
            }) {
                VStack(spacing: 20) {
                    if isFinding {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
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
            // 코사인 유사도 점수 표시
            Text(String(format: "Similarity Score: %.2f%%", similarityScore * 100))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.94))
                .padding(.top, 10)
            
            HStack(spacing: 0) {
                // 나 (왼쪽)
                ProfileComparisonColumn(title: "Me", data: myData, isMatch: false)
                
                // 상대방 (오른쪽)
                ProfileComparisonColumn(title: "Co-sign", data: otherData, isMatch: true)
            }
        }
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
    
    private func fetchMyData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snap, _ in
            self.currentUserData = snap?.data()
        }
    }
    
    // MARK: - Matching Logic (Cosine Similarity)
    private func startMatchingProcess() {
        guard let myData = currentUserData else { return }
        isFinding = true
        
        let db = Firestore.firestore()
        let myGender = myData["gender"] as? String ?? ""
        let targetGender = (myGender == "Male") ? "Female" : "Male"
        
        db.collection("users")
            .whereField("gender", isEqualTo: targetGender)
            .whereField("isProfileComplete", isEqualTo: true)
            .getDocuments { querySnapshot, error in
                guard let docs = querySnapshot?.documents, !docs.isEmpty else {
                    isFinding = false
                    return
                }
                
                var bestMatch: [String: Any]? = nil
                var maxSimilarity: Double = -1.0
                
                let myVector = Vectorize(myData)
                
                for doc in docs {
                    let otherData = doc.data()
                    // Ensure we don't match with ourselves if somehow UID is same (though filtered by gender)
                    if doc.documentID == Auth.auth().currentUser?.uid { continue }
                    
                    let otherVector = Vectorize(otherData)
                    let sim = cosineSimilarity(myVector, otherVector)
                    
                    if sim > maxSimilarity {
                        maxSimilarity = sim
                        bestMatch = otherData
                    }
                }
                
                withAnimation(.spring()) {
                    self.matchedUser = bestMatch
                    self.similarityScore = maxSimilarity
                    self.isFinding = false
                }
            }
    }
    
    // MARK: - Vectorization Helper
    private func Vectorize(_ data: [String: Any]) -> [Double] {
        var vector: [Double] = []
        
        // 1. Birthday (Year) - 1990 기준 정규화
        let bday = data["birthday"] as? String ?? "19900101"
        let year = Double(bday.prefix(4)) ?? 1990.0
        vector.append((year - 1970) / 50.0) 
        
        // 2. Physical
        let h = Double(data["height"] as? String ?? "170") ?? 170.0
        let w = Double(data["weight"] as? String ?? "65") ?? 65.0
        vector.append(h / 200.0)
        vector.append(w / 100.0)
        
        // 3. MBTI (Simple mapping)
        let mbti = data["mbti"] as? String ?? "XXXX"
        vector.append(mbti.contains("E") ? 1 : 0)
        vector.append(mbti.contains("S") ? 1 : 0)
        vector.append(mbti.contains("T") ? 1 : 0)
        vector.append(mbti.contains("J") ? 1 : 0)
        
        // 4. Economics (Income, Assets)
        let inc = Double(data["annualIncome"] as? String ?? "0") ?? 0
        let liq = Double(data["liquidAssets"] as? String ?? "0") ?? 0
        let fix = Double(data["fixedAssets"] as? String ?? "0") ?? 0
        vector.append(log1p(inc) / 10.0)
        vector.append(log1p(liq) / 10.0)
        vector.append(log1p(fix) / 10.0)
        
        // 5. Education Level
        let eduLevel: Double
        if !(data["graduateSchool"] as? String ?? "").isEmpty { eduLevel = 5 }
        else if !(data["university"] as? String ?? "").isEmpty { eduLevel = 4 }
        else if !(data["highSchool"] as? String ?? "").isEmpty { eduLevel = 3 }
        else { eduLevel = 2 }
        vector.append(eduLevel / 5.0)
        
        // 6. Hobbies (Binary matching)
        let hobbies = data["hobbies"] as? [String] ?? []
        let allPossibleHobbies = ["Movies", "Music", "Sports", "Travel", "Gaming", "Food", "Pets"]
        for h in allPossibleHobbies {
            vector.append(hobbies.contains(h) ? 1.0 : 0.0)
        }
        
        return vector
    }
    
    private func cosineSimilarity(_ v1: [Double], _ v2: [Double]) -> Double {
        guard v1.count == v2.count else { return 0 }
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let mag1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let mag2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        return (mag1 * mag2 == 0) ? 0 : dotProduct / (mag1 * mag2)
    }

    // MARK: - Mock Data Generation (Fixed with unique IDs)
    private func generateMockUsers() {
        isGeneratingData = true
        let db = Firestore.firestore()
        let lastNames = ["Kim", "Lee", "Park", "Choi", "Jung", "Kang", "Cho", "Yoon"]
        let firstNames = ["Minsoo", "Jiho", "Sooeyeon", "Yujin", "Donghyun", "Seojun", "Hayun", "Jiwoo"]
        let nationalities = ["Korea, Republic of", "USA", "Japan", "China", "Canada"]
        let jobs = ["IT & Tech", "Finance", "Medical", "Education", "Arts", "Service"]
        let mbtis = ["INTJ", "ENFP", "INFJ", "ENTP", "ISTJ", "ISFP", "ESTJ", "ESFJ"]
        let hList = ["Movies", "Music", "Sports", "Travel", "Gaming", "Food", "Pets"]
        
        let group = DispatchGroup()
        for i in 1...10 {
            group.enter()
            let isMale = (i % 2 == 0)
            let data: [String: Any] = [
                "lastName": lastNames.randomElement()!,
                "firstName": firstNames.randomElement()!,
                "birthday": "199\(Int.random(in: 0...9))\(String(format: "%02d", Int.random(in: 1...12)))\(String(format: "%02d", Int.random(in: 1...28)))",
                "gender": isMale ? "Male" : "Female",
                "nationality": nationalities.randomElement()!,
                "height": isMale ? "\(Int.random(in: 172...185))" : "\(Int.random(in: 158...170))",
                "weight": isMale ? "\(Int.random(in: 65...85))" : "\(Int.random(in: 45...60))",
                "bloodType": ["A", "B", "AB", "O"].randomElement()!,
                "mbti": mbtis.randomElement()!,
                "hobbies": Array(hList.shuffled().prefix(3)),
                "employmentType": "Regular",
                "jobField": jobs.randomElement()!,
                "annualIncome": "\(Int.random(in: 3000...9000))",
                "liquidAssets": "\(Int.random(in: 1000...5000))",
                "fixedAssets": "\(Int.random(in: 5000...20000))",
                "elementarySchool": "Mock Elementary",
                "middleSchool": "Mock Middle",
                "highSchool": "Mock High",
                "university": "Mock Univ",
                "isProfileComplete": true,
                "profileImageUrl": ""
            ]
            db.collection("users").document(UUID().uuidString).setData(data) { _ in group.leave() }
        }
        group.notify(queue: .main) { isGeneratingData = false }
    }
}

// MARK: - Send Sign Overlay
extension MainView {
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
                    // Back 버튼
                    Button(action: { showSendSignConfirm = false }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 65)
                            .background(Color(white: 0.95))
                            .cornerRadius(15)
                    }
                    
                    // Send 버튼
                    Button(action: {
                        if mySignBalance >= 100 {
                            mySignBalance -= 100
                            isSignSent = true
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

// MARK: - Subviews
struct ProfileComparisonColumn: View {
    let title: String
    let data: [String: Any]
    let isMatch: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isMatch ? .blue : .gray)
                .padding(.top, 15)
            
            // 프로필 사진 (가로세로 동일 네모, 너비 꽉 차게)
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: geo.size.width * 0.4))
                            .foregroundColor(.gray.opacity(0.3))
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(12)
                    .frame(width: geo.size.width, height: geo.size.width)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 10)
            
            VStack(spacing: 12) {
                InfoLabel(text: "\(data["lastName"] as? String ?? "")\(data["firstName"] as? String ?? "")", icon: "person", isBold: true)
                InfoLabel(text: data["birthday"] as? String ?? "Unknown", icon: "calendar")
                InfoLabel(text: "\(data["height"] as? String ?? "0")cm", icon: "ruler")
                InfoLabel(text: "\(data["weight"] as? String ?? "0")kg", icon: "scalemass")
                InfoLabel(text: data["mbti"] as? String ?? "None", icon: "brain")
                
                Text(getHighestEdu(data))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.bottom, 25)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func getHighestEdu(_ data: [String: Any]) -> String {
        if !(data["graduateSchool"] as? String ?? "").isEmpty { return "Graduate" }
        if !(data["university"] as? String ?? "").isEmpty { return "University" }
        if !(data["highSchool"] as? String ?? "").isEmpty { return "High School" }
        return "Elementary"
    }
}

struct InfoLabel: View {
    let text: String
    let icon: String
    var isBold: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Text(text)
                .font(.system(size: 15, weight: isBold ? .bold : .regular))
        }
    }
}

#Preview {
    MainView(isProfileComplete: true)
}

#Preview {
    MainView(isProfileComplete: false)
}
