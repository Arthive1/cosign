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
    @State private var isEditingProfile: Bool = false
    @State private var showProfileMenu: Bool = false
    
    // 매칭 관련 상태
    @State private var matchedUser: [String: Any]? = nil
    @State private var currentUserData: [String: Any]? = nil
    @State private var similarityScore: Double = 0.0
    @State private var showSendSignConfirm: Bool = false
    @State private var isSignSent: Bool = false
    @State private var sentSignUserIds: Set<String> = []
    @State private var pendingUsers: [[String: Any]] = []
    @State private var receivedUsers: [[String: Any]] = []
    @State private var selectedTab: Int = 0
    @State private var ignoredIds: Set<String> = []
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // 1. Sign 탭 (Find Co-sign)
                CoSignHomeView(
                    isProfileComplete: isProfileComplete,
                    mySignBalance: $mySignBalance,
                    showProfileSetup: $showProfileSetup,
                    showIncompleteAlert: $showIncompleteAlert,
                    isFinding: $isFinding,
                    matchedUser: $matchedUser,
                    currentUserData: $currentUserData,
                    similarityScore: $similarityScore,
                    showSendSignConfirm: $showSendSignConfirm,
                    isSignSent: $isSignSent,
                    sentSignUserIds: $sentSignUserIds,
                    pendingUsers: $pendingUsers,
                    fetchMyData: fetchMyData,
                    startMatchingProcess: startMatchingProcess,
                    generateMockUsers: generateMockUsers,
                    isGeneratingData: isGeneratingData
                )
                .tabItem {
                    Image(systemName: "waveform")
                    Text("Sign")
                }
                .tag(0)
                
                // 2. Chat 탭 (Balloon 아이콘)
                ChatListView(
                    currentUserData: currentUserData,
                    mySignBalance: $mySignBalance,
                    pendingUsers: $pendingUsers,
                    receivedUsers: $receivedUsers,
                    sentSignUserIds: $sentSignUserIds
                )
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chat")
                }
                .tag(1)
            }
            .accentColor(Color(red: 0.53, green: 0.75, blue: 0.94))
            .navigationTitle(selectedTab == 0 ? "Sign" : "Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden)
            .sheet(isPresented: $showProfileSetup) {
                ProfileSetupView(headerTitle: isEditingProfile ? "Change Profile" : "Complete Your Profile")
                    .onDisappear { 
                        isEditingProfile = false 
                        fetchMyData()
                    }
            }
            .onAppear {
                fetchMyData()
                // Mock Received Sign Data
                if receivedUsers.isEmpty {
                    receivedUsers = [
                        ["lastName": "Lee", "firstName": "Seulgi", "jobField": "Designer", "uid": "mock_rec_1", "profileImageUrl": ""],
                        ["lastName": "Park", "firstName": "Chorong", "jobField": "Teacher", "uid": "mock_rec_2", "profileImageUrl": ""]
                    ]
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowProfileMenu"))) { _ in
                showProfileMenu = true
            }
            .alert("Profile Incomplete", isPresented: $showIncompleteAlert) {
                Button("Update Profile") {
                    showProfileSetup = true
                }
                Button("Later", role: .cancel) { }
            } message: {
                Text("Please update your profile first to use this feature.")
            }
            .confirmationDialog("Profile Menu", isPresented: $showProfileMenu, titleVisibility: .hidden) {
                Button("Edit Profile") {
                    isEditingProfile = true
                    showProfileSetup = true
                }
                Button("Log Out", role: .destructive) {
                    try? Auth.auth().signOut()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private func fetchMyData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snap, _ in
            self.currentUserData = snap?.data()
        }
    }
    
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
                    var otherData = doc.data()
                    let otherId = doc.documentID
                    otherData["uid"] = otherId
                    
                    if otherId == Auth.auth().currentUser?.uid { continue }
                    if sentSignUserIds.contains(otherId) { continue }
                    if ignoredIds.contains(otherId) { continue } // 무시 목록 추가
                    
                    let otherVector = Vectorize(otherData)
                    let sim = cosineSimilarity(myVector, otherVector)
                    
                    if sim > maxSimilarity {
                        maxSimilarity = sim
                        bestMatch = otherData
                    }
                }
                
                // 2초 뒤에 결과를 반영하여 스피너 UI가 보이도록 딜레이 추가
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        if let match = bestMatch, let matchId = match["uid"] as? String {
                            ignoredIds.insert(matchId) // 현재 매칭된 유저를 무시 목록에 추가 (다음 매칭을 위해)
                        }
                        self.matchedUser = bestMatch
                        self.similarityScore = maxSimilarity
                        self.isFinding = false
                    }
                }
            }
    }
    
    private func Vectorize(_ data: [String: Any]) -> [Double] {
        var vector: [Double] = []
        let bday = data["birthday"] as? String ?? "19900101"
        let year = Double(bday.prefix(4)) ?? 1990.0
        vector.append((year - 1970) / 50.0) 
        
        let h = Double(data["height"] as? String ?? "170") ?? 170.0
        let w = Double(data["weight"] as? String ?? "65") ?? 65.0
        vector.append(h / 200.0)
        vector.append(w / 100.0)
        
        let mbti = data["mbti"] as? String ?? "XXXX"
        vector.append(mbti.contains("E") ? 1 : 0)
        vector.append(mbti.contains("S") ? 1 : 0)
        vector.append(mbti.contains("T") ? 1 : 0)
        vector.append(mbti.contains("J") ? 1 : 0)
        
        let inc = Double(data["annualIncome"] as? String ?? "0") ?? 0
        let liq = Double(data["liquidAssets"] as? String ?? "0") ?? 0
        let fix = Double(data["fixedAssets"] as? String ?? "0") ?? 0
        vector.append(log1p(inc) / 10.0)
        vector.append(log1p(liq) / 10.0)
        vector.append(log1p(fix) / 10.0)
        
        let eduLevel: Double
        if !(data["graduateSchool"] as? String ?? "").isEmpty { eduLevel = 5 }
        else if !(data["university"] as? String ?? "").isEmpty { eduLevel = 4 }
        else if !(data["highSchool"] as? String ?? "").isEmpty { eduLevel = 3 }
        else { eduLevel = 2 }
        vector.append(eduLevel / 5.0)
        
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
                "phoneNumber": "010-\(Int.random(in: 1000...9999))-\(Int.random(in: 1000...9999))",
                "isProfileComplete": true,
                "profileImageUrl": ""
            ]
            db.collection("users").document(UUID().uuidString).setData(data) { _ in group.leave() }
        }
        group.notify(queue: .main) { isGeneratingData = false }
    }
}
