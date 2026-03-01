import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    var headerTitle: String = "Complete Your Profile"
    
    // 섹션별 편집 모드 관리
    @State private var editingSection: SetupSection? = nil
    
    // --- 1. Profile 관련 ---
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: String = ""
    @State private var selectedGender: String = "Select"
    @State private var selectedNationality: String = "Korea, Republic of"
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var selectedBloodType: String = "Select"
    @State private var selectedMBTI: String = "Select"
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var avatarData: Data?
    
    // --- 2. Economics 관련 ---
    @State private var employmentType: String = "Select"
    @State private var jobField: String = "Select"
    @State private var annualIncome: String = ""
    @State private var liquidAssets: String = ""
    @State private var fixedAssets: String = ""
    
    // --- 3. Education 관련 ---
    @State private var elementarySchool: String = ""
    @State private var isElementaryChecked: Bool = false
    @State private var middleSchool: String = ""
    @State private var isMiddleChecked: Bool = false
    @State private var highSchool: String = ""
    @State private var isHighChecked: Bool = false
    @State private var university: String = ""
    @State private var isUniversityChecked: Bool = false
    @State private var graduateSchool: String = ""
    @State private var isGraduateChecked: Bool = false
    
    // --- 4. Hobbies 관련 ---
    @State private var selectedHobbies: Set<String> = []
    
    // 섹션별 선택 상태 관리 (바텀 시트용)
    @State private var activeSelection: SelectionField? = nil
    
    enum SelectionField: Identifiable {
        case gender, nationality, blood, mbti, employment, jobField
        var id: Int { hashValue }
        
        var title: String {
            switch self {
            case .gender: return "Select Gender"
            case .nationality: return "Select Nationality"
            case .blood: return "Select Blood Type"
            case .mbti: return "Select MBTI"
            case .employment: return "Select Employment Status"
            case .jobField: return "Select Job Field"
            }
        }
    }
    
    // 섹션 완료 상태 (로직으로 판단)
    var isProfileDone: Bool { !firstName.isEmpty && !lastName.isEmpty && !birthday.isEmpty && selectedGender != "Select" }
    var isEconomicsDone: Bool { employmentType != "Select" && jobField != "Select" }
    var isAnySectionDone: Bool { isProfileDone || isEconomicsDone || isEducationDone || isHobbiesDone }
    var isAllDone: Bool { isProfileDone && isEconomicsDone && isEducationDone && isHobbiesDone }
    
    var isEducationDone: Bool { !elementarySchool.isEmpty }
    var isHobbiesDone: Bool { !selectedHobbies.isEmpty }
    
    // 학력 입력 관련 추가 상태
    @State private var editingEducationField: EducationField? = nil
    @State private var showEducationAlert: Bool = false
    
    enum EducationField: String, Identifiable {
        case elementary = "Elementary", middle = "Middle", high = "High", university = "University", graduate = "Graduate"
        var id: String { self.rawValue }
    }
    
    @State private var isLoading: Bool = false
    @AppStorage("mySignBalance") private var mySignBalance: Int = 0
    @State private var wasSectionDoneBeforeEditing: Bool = false
    
    enum SetupSection: String, Identifiable {
        case profile = "Profile", economics = "Economics", education = "Education", hobbies = "Hobbies"
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 1.0).ignoresSafeArea()
                
                VStack(spacing: 25) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(headerTitle)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        Text("Finish all categories to unlock features")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // 대시보드 그리드
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                        SectionCard(type: .profile, isDone: isProfileDone) { prepareEditing(.profile) }
                        SectionCard(type: .economics, isDone: isEconomicsDone) { prepareEditing(.economics) }
                        SectionCard(type: .education, isDone: isEducationDone) { prepareEditing(.education) }
                        SectionCard(type: .hobbies, isDone: isHobbiesDone) { prepareEditing(.hobbies) }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // 최종 완료 버튼
                    Button(action: {
                        handleFinalSave()
                    }) {
                        Text("Finish Update")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(red: 0.53, green: 0.75, blue: 0.94))
                            .cornerRadius(20)
                            .shadow(color: Color(red: 0.53, green: 0.75, blue: 0.94).opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
                
                if isLoading {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView("Finalizing...").padding().background(Color.white).cornerRadius(15).shadow(radius: 10)
                }
            }
            .onAppear {
                fetchExistingProfile()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $editingSection) { section in
                NavigationStack {
                    SectionEditView(section: section)
                        .navigationTitle(section.rawValue)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .sheet(item: $activeSelection) { field in
                    SelectionListView(field: field)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
                .sheet(item: $editingEducationField) { field in
                    EducationNameInputView(field: field)
                        .presentationDetents([.height(250)])
                }
                .alert("Incomplete Sequence", isPresented: $showEducationAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please input the previous education institution first.")
                }
            }
        }
    }
    
    // MARK: - Education Name Input View
    func EducationNameInputView(field: EducationField) -> some View {
        let binding: Binding<String> = {
            switch field {
            case .elementary: return $elementarySchool
            case .middle: return $middleSchool
            case .high: return $highSchool
            case .university: return $university
            case .graduate: return $graduateSchool
            }
        }()
        
        return VStack(spacing: 25) {
            Text("\(field.rawValue) School Name")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.top, 30)
            
            CustomTextField(placeholder: "Enter school name", text: binding)
                .padding(.horizontal, 30)
            
            Button("Save") { editingEducationField = nil }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color(red: 0.53, green: 0.75, blue: 0.94))
                .cornerRadius(12)
                .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    // MARK: - Selection Sheet View
    func SelectionListView(field: SelectionField) -> some View {
        let items: [String] = {
            switch field {
            case .gender: return ["Male", "Female"]
            case .nationality: return ["Korea, Republic of", "USA", "Japan", "China", "UK", "France", "Germany", "Canada"]
            case .blood: return ["A", "B", "AB", "O"]
            case .mbti: return ["INTJ", "INTP", "ENTJ", "ENTP", "INFJ", "INFP", "ENFJ", "ENFP", "ISTJ", "ISFJ", "ESTJ", "ESFJ", "ISTP", "ISFP", "ESTP", "ESFP"]
            case .employment: return ["Regular", "Non-regular", "Freelancer"]
            case .jobField: return ["Finance", "IT & Tech", "Medical", "Education", "Public Service", "Legal", "Arts", "Service", "Sales", "Construction", "Production", "Other (etc)"]
            }
        }()
        
        let selection: Binding<String> = {
            switch field {
            case .gender: return $selectedGender
            case .nationality: return $selectedNationality
            case .blood: return $selectedBloodType
            case .mbti: return $selectedMBTI
            case .employment: return $employmentType
            case .jobField: return $jobField
            }
        }()
        
        return VStack(spacing: 0) {
            Text(field.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.vertical, 20)
            
            List {
                ForEach(items, id: \.self) { item in
                    Button(action: {
                        selection.wrappedValue = item
                        activeSelection = nil
                    }) {
                        HStack {
                            Text(item)
                                .foregroundColor(selection.wrappedValue == item ? .primary : .secondary)
                                .font(.system(size: 16, weight: isSelected(item, for: field) ? .bold : .medium, design: .rounded))
                            Spacer()
                            if isSelected(item, for: field) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.94))
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.plain)
        }
    }
    
    func isSelected(_ item: String, for field: SelectionField) -> Bool {
        switch field {
        case .gender: return selectedGender == item
        case .nationality: return selectedNationality == item
        case .blood: return selectedBloodType == item
        case .mbti: return selectedMBTI == item
        case .employment: return employmentType == item
        case .jobField: return jobField == item
        }
    }
    
    // MARK: - Section Card View
    func SectionCard(type: SetupSection, isDone: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(isDone ? Color.white.opacity(0.5) : Color(red: 0.53, green: 0.75, blue: 0.94).opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isDone ? "checkmark.circle.fill" : iconName(for: type))
                        .font(.title2)
                        .foregroundColor(isDone ? .white : Color(red: 0.53, green: 0.75, blue: 0.94))
                }
                
                Text(type.rawValue)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isDone ? .white : Color(red: 0.2, green: 0.2, blue: 0.3))
                
                Text(isDone ? "Completed" : "Not Finished")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isDone ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isDone ? Color(red: 0.67, green: 0.82, blue: 0.94) : Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(isDone ? Color.clear : Color.black.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    func iconName(for type: SetupSection) -> String {
        switch type {
        case .profile: return "person.fill"
        case .economics: return "briefcase.fill"
        case .education: return "graduationcap.fill"
        case .hobbies: return "heart.fill"
        }
    }
    
    // MARK: - Edit Views
    @ViewBuilder
    func SectionEditView(section: SetupSection) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                switch section {
                case .profile: profileForm
                case .economics: economicsForm
                case .education: educationForm
                case .hobbies: hobbiesForm
                }
            }
            .padding(30)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    editingSection = nil
                }
                .fontWeight(.bold)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    let isDoneNow: Bool
                    switch section {
                    case .profile: isDoneNow = isProfileDone
                    case .economics: isDoneNow = isEconomicsDone
                    case .education: isDoneNow = isEducationDone
                    case .hobbies: isDoneNow = isHobbiesDone
                    }
                    
                    if !wasSectionDoneBeforeEditing && isDoneNow {
                        mySignBalance += 100
                    }
                    
                    editingSection = nil
                }
                .fontWeight(.bold)
            }
        }
    }
    
    var profileForm: some View {
        VStack(spacing: 15) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                if let avatarImage {
                    avatarImage.resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())
                } else {
                    Circle().fill(Color.gray.opacity(0.1)).frame(width: 100, height: 100)
                        .overlay(Image(systemName: "camera.fill").foregroundColor(.gray))
                }
            }
            .onChange(of: avatarItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        avatarData = data
                        avatarImage = Image(uiImage: uiImage)
                    }
                }
            }
            
            HStack { CustomTextField(placeholder: "Last Name", text: $lastName); CustomTextField(placeholder: "First Name", text: $firstName) }
            CustomTextField(placeholder: "Birthday (YYYYMMDD)", text: $birthday).keyboardType(.numberPad)
            HStack {
                setupSelectionField(title: selectedGender == "Select" ? "Gender" : selectedGender, field: .gender)
                setupSelectionField(title: selectedNationality, field: .nationality)
            }
            HStack { CustomTextField(placeholder: "Height (cm)", text: $height).keyboardType(.numberPad); CustomTextField(placeholder: "Weight (kg)", text: $weight).keyboardType(.numberPad) }
            HStack {
                setupSelectionField(title: selectedBloodType == "Select" ? "Blood" : "Type \(selectedBloodType)", field: .blood)
                setupSelectionField(title: selectedMBTI == "Select" ? "MBTI" : selectedMBTI, field: .mbti)
            }
        }
    }
    
    var economicsForm: some View {
        VStack(spacing: 15) {
            setupSelectionField(title: employmentType == "Select" ? "Employment Status" : employmentType, field: .employment)
            setupSelectionField(title: jobField == "Select" ? "Job Field" : jobField, field: .jobField)
            CustomTextField(placeholder: "Annual Income ($)", text: $annualIncome).keyboardType(.numberPad)
            CustomTextField(placeholder: "Liquid Assets ($)", text: $liquidAssets).keyboardType(.numberPad)
            CustomTextField(placeholder: "Fixed Assets ($)", text: $fixedAssets).keyboardType(.numberPad)
        }
    }
    
    var educationForm: some View {
        VStack(spacing: 15) {
            educationCard(field: .elementary, isDone: !elementarySchool.isEmpty)
            educationCard(field: .middle, isDone: !middleSchool.isEmpty)
            educationCard(field: .high, isDone: !highSchool.isEmpty)
            educationCard(field: .university, isDone: !university.isEmpty)
            educationCard(field: .graduate, isDone: !graduateSchool.isEmpty)
        }
    }
    
    func educationCard(field: EducationField, isDone: Bool) -> some View {
        Button(action: { 
            if canEdit(field: field) {
                editingEducationField = field
            } else {
                showEducationAlert = true
            }
        }) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(isDone ? Color.white.opacity(0.3) : Color(red: 0.53, green: 0.75, blue: 0.94).opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: isDone ? "checkmark" : "graduationcap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isDone ? .white : Color(red: 0.53, green: 0.75, blue: 0.94))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(field.rawValue + " School")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(isDone ? .white : Color(red: 0.2, green: 0.2, blue: 0.3))
                    if isDone {
                        Text(schoolName(for: field))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(isDone ? .white.opacity(0.7) : .secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isDone ? Color(red: 0.67, green: 0.82, blue: 0.94) : Color(red: 0.96, green: 0.96, blue: 0.98))
            )
        }
    }
    
    func canEdit(field: EducationField) -> Bool {
        switch field {
        case .elementary: return true
        case .middle: return !elementarySchool.isEmpty
        case .high: return !middleSchool.isEmpty
        case .university: return !highSchool.isEmpty
        case .graduate: return !university.isEmpty
        }
    }
    
    func schoolName(for field: EducationField) -> String {
        switch field {
        case .elementary: return elementarySchool
        case .middle: return middleSchool
        case .high: return highSchool
        case .university: return university
        case .graduate: return graduateSchool
        }
    }
    
    var hobbiesForm: some View {
        let hobbiesItems = [
            ("Movies", "film"), ("Autos", "car"), ("Music", "music.note"), ("Pets", "pawprint"),
            ("Sports", "figure.run"), ("Travel", "airplane"), ("Gaming", "gamecontroller"), ("Blogs", "person.text.rectangle"),
            ("Comedy", "face.smiling"), ("Entertain", "play.tv"), ("News", "newspaper"), ("Style", "tshirt"),
            ("Education", "graduationcap"), ("Sci & Tech", "cpu"), ("Social", "heart.fill"), ("Food", "fork.knife")
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(hobbiesItems, id: \.0) { hobby, icon in
                HobbyButton(title: hobby, icon: icon, isSelected: selectedHobbies.contains(hobby)) {
                    if selectedHobbies.contains(hobby) { selectedHobbies.remove(hobby) }
                    else { selectedHobbies.insert(hobby) }
                }
            }
        }
    }
    
    func setupSelectionField(title: String, field: SelectionField) -> some View {
        Button(action: { activeSelection = field }) {
            HStack {
                Text(title).foregroundColor(title.contains("Select") || title.contains("Status") || title.contains("Gender") || title.contains("Blood") || title.contains("MBTI") || title.contains("Field") ? .secondary : .primary).lineLimit(1)
                Spacer(); Image(systemName: "chevron.down").font(.caption).foregroundColor(.secondary)
            }
            .padding().frame(maxWidth: .infinity).background(Color(red: 0.96, green: 0.96, blue: 0.98)).cornerRadius(12)
        }
    }
    
    // MARK: - Final Save Logic
    func handleFinalSave() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        if let data = avatarData {
            let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
            storageRef.putData(data, metadata: nil) { _, _ in
                storageRef.downloadURL { url, _ in
                    updateFirestore(uid: uid, imageUrl: url?.absoluteString ?? "")
                }
            }
        } else {
            updateFirestore(uid: uid, imageUrl: "")
        }
    }
    
    func updateFirestore(uid: String, imageUrl: String) {
        let db = Firestore.firestore()
        var updateData: [String: Any] = [
            "lastName": lastName, "firstName": firstName, "birthday": birthday, "gender": selectedGender,
            "nationality": selectedNationality, "height": height, "weight": weight, "bloodType": selectedBloodType,
            "mbti": selectedMBTI, "hobbies": Array(selectedHobbies), "employmentType": employmentType,
            "jobField": jobField, "annualIncome": annualIncome, "liquidAssets": liquidAssets, "fixedAssets": fixedAssets,
            "elementarySchool": elementarySchool, "middleSchool": middleSchool, "highSchool": highSchool,
            "university": university, "graduateSchool": graduateSchool, "isProfileComplete": isAllDone
        ]
        if !imageUrl.isEmpty { updateData["profileImageUrl"] = imageUrl }
        
        db.collection("users").document(uid).updateData(updateData) { _ in
            isLoading = false
            dismiss()
        }
    }
    
    private func fetchExistingProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            isLoading = false
            if let data = snapshot?.data() {
                // Profile
                self.lastName = data["lastName"] as? String ?? ""
                self.firstName = data["firstName"] as? String ?? ""
                self.birthday = data["birthday"] as? String ?? ""
                self.selectedGender = data["gender"] as? String ?? "Select"
                self.selectedNationality = data["nationality"] as? String ?? "Korea, Republic of"
                self.height = data["height"] as? String ?? ""
                self.weight = data["weight"] as? String ?? ""
                self.selectedBloodType = data["bloodType"] as? String ?? "Select"
                self.selectedMBTI = data["mbti"] as? String ?? "Select"
                
                // Economics
                self.employmentType = data["employmentType"] as? String ?? "Select"
                self.jobField = data["jobField"] as? String ?? "Select"
                self.annualIncome = data["annualIncome"] as? String ?? ""
                self.liquidAssets = data["liquidAssets"] as? String ?? ""
                self.fixedAssets = data["fixedAssets"] as? String ?? ""
                
                // Education
                self.elementarySchool = data["elementarySchool"] as? String ?? ""
                self.middleSchool = data["middleSchool"] as? String ?? ""
                self.highSchool = data["highSchool"] as? String ?? ""
                self.university = data["university"] as? String ?? ""
                self.graduateSchool = data["graduateSchool"] as? String ?? ""
                
                // Hobbies
                if let hobbies = data["hobbies"] as? [String] {
                    self.selectedHobbies = Set(hobbies)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func prepareEditing(_ section: SetupSection) {
        switch section {
        case .profile: wasSectionDoneBeforeEditing = isProfileDone
        case .economics: wasSectionDoneBeforeEditing = isEconomicsDone
        case .education: wasSectionDoneBeforeEditing = isEducationDone
        case .hobbies: wasSectionDoneBeforeEditing = isHobbiesDone
        }
        editingSection = section
    }
}
