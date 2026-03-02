import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import MapKit

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    var headerTitle: String = "Complete Your Profile"
    
    // 섹션별 편집 모드 관리
    @State private var editingSection: SetupSection? = nil
    
    // --- 1. Profile 관련 ---
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var nickname: String = ""
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
    @State private var profileImageUrl: String = ""
    
    // --- 1-1. Address 관련 ---
    @State private var address: String = ""
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var showAddressSearch: Bool = false
    @State private var addressSearchText: String = ""
    @State private var addressSuggestions: [MKMapItem] = []
    @State private var isSearchingAddress: Bool = false
    
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
    var isProfileDone: Bool { 
        !firstName.isEmpty && !lastName.isEmpty && !nickname.isEmpty && !birthday.isEmpty && 
        selectedGender != "Select" && !address.isEmpty && (!profileImageUrl.isEmpty || avatarData != nil)
    }
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
    @State private var showBonusAlert: Bool = false
    
    // 최종 확인 팝업 관련 상태
    @State private var showInitialConfirm: Bool = false
    @State private var showEditConfirm: Bool = false
    @State private var showInsufficientSignsAlert: Bool = false
    
    // 학교 검색 결과
    @State private var schoolSuggestions: [MKMapItem] = []
    @State private var isSearchingSchools: Bool = false
    
    // 수정 여부 판단을 위한 원본 데이터 저장
    @State private var originalData: [String: Any] = [:]
    
    var hasChanges: Bool {
        // 주요 필드들 비교
        if firstName != (originalData["firstName"] as? String ?? "") { return true }
        if lastName != (originalData["lastName"] as? String ?? "") { return true }
        if nickname != (originalData["nickname"] as? String ?? "") { return true }
        if birthday != (originalData["birthday"] as? String ?? "") { return true }
        if selectedGender != (originalData["gender"] as? String ?? "Select") { return true }
        if selectedNationality != (originalData["nationality"] as? String ?? "Korea, Republic of") { return true }
        if height != (originalData["height"] as? String ?? "") { return true }
        if weight != (originalData["weight"] as? String ?? "") { return true }
        if selectedBloodType != (originalData["bloodType"] as? String ?? "Select") { return true }
        if selectedMBTI != (originalData["mbti"] as? String ?? "Select") { return true }
        if address != (originalData["address"] as? String ?? "") { return true }
        if employmentType != (originalData["employmentType"] as? String ?? "Select") { return true }
        if jobField != (originalData["jobField"] as? String ?? "Select") { return true }
        if annualIncome != (originalData["annualIncome"] as? String ?? "") { return true }
        if liquidAssets != (originalData["liquidAssets"] as? String ?? "") { return true }
        if fixedAssets != (originalData["fixedAssets"] as? String ?? "") { return true }
        if elementarySchool != (originalData["elementarySchool"] as? String ?? "") { return true }
        if middleSchool != (originalData["middleSchool"] as? String ?? "") { return true }
        if highSchool != (originalData["highSchool"] as? String ?? "") { return true }
        if university != (originalData["university"] as? String ?? "") { return true }
        if graduateSchool != (originalData["graduateSchool"] as? String ?? "") { return true }
        
        let originalHobbies = Set(originalData["hobbies"] as? [String] ?? [])
        if selectedHobbies != originalHobbies { return true }
        
        if avatarData != nil { return true } // 사진 변경 시 수정으로 판단
        
        return false
    }
    
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
                        if headerTitle == "Change Profile" {
                            // 수정된 내용이 있는지 확인
                            if hasChanges {
                                if mySignBalance >= 100 {
                                    showEditConfirm = true
                                } else {
                                    showInsufficientSignsAlert = true
                                }
                            } else {
                                // 변경사항이 없으면 저장을 건너뛰고 바로 닫기
                                dismiss()
                            }
                        } else {
                            // 신규 가입 후 초기 설정 모드 (Complete Your Profile)
                            // 모든 항목이 완료되었든 일부만 되었든 초기 설정 중에는 팝업 없이 즉시 저장 (비용 발생 없음)
                            handleFinalSave()
                        }
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
                
                // --- 팝업 오버레이들 ---
                if showBonusAlert { bonusPopupOverlay }
                if showInitialConfirm { initialConfirmOverlay }
                if showEditConfirm { editConfirmOverlay }
                if showInsufficientSignsAlert { insufficientSignsOverlay }
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
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showAddressSearch) {
                    AddressInputView()
                        .presentationDetents([.medium, .large])
                }
                .alert("Incomplete Sequence", isPresented: $showEducationAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please input the previous education institution first.")
                }
            }
        }
    }
    
    // MARK: - Address Input View
    func AddressInputView() -> some View {
        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("Search Address")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Spacer()
                Button(action: { showAddressSearch = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.3))
                        .font(.title2)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 25)
            .padding(.bottom, 15)
            
            // Search Bar
            CustomTextField(placeholder: "Enter your address...", text: $addressSearchText)
                .padding(.horizontal, 30)
                .onChange(of: addressSearchText) { oldValue, newValue in
                    if newValue.count > 1 {
                        searchAddress(query: newValue)
                    } else {
                        addressSuggestions = []
                    }
                }
            
            if isSearchingAddress {
                ProgressView()
                    .padding(.top, 20)
            }
            
            // Suggestions List
            if !addressSuggestions.isEmpty {
                List(addressSuggestions, id: \.self) { item in
                    Button(action: {
                        self.address = item.placemark.title ?? (item.name ?? "")
                        self.latitude = item.placemark.coordinate.latitude
                        self.longitude = item.placemark.coordinate.longitude
                        addressSuggestions = []
                        addressSearchText = ""
                        showAddressSearch = false
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Unknown Place")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            if let addr = item.placemark.title {
                                Text(addr)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .padding(.top, 10)
            }
            
            Spacer()
        }
    }
    
    private func searchAddress(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        isSearchingAddress = true
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearchingAddress = false
            if let response = response {
                self.addressSuggestions = response.mapItems
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
        
        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(field.rawValue) School Selection")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Spacer()
                Button(action: { editingEducationField = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.3))
                        .font(.title2)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 25)
            .padding(.bottom, 15)
            
            // Search Bar
            CustomTextField(placeholder: "Search for your school...", text: binding)
                .padding(.horizontal, 30)
                .onChange(of: binding.wrappedValue) { oldValue, newValue in
                    if !newValue.isEmpty && newValue.count > 1 {
                        searchSchools(query: newValue, field: field)
                    } else {
                        schoolSuggestions = []
                    }
                }
            
            if isSearchingSchools {
                ProgressView()
                    .padding(.top, 20)
            }
            
            // Suggestions List
            if !schoolSuggestions.isEmpty {
                List(schoolSuggestions, id: \.self) { item in
                    Button(action: {
                        binding.wrappedValue = item.name ?? ""
                        schoolSuggestions = []
                        editingEducationField = nil
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Unknown School")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            if let addr = item.placemark.title {
                                Text(addr)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .padding(.top, 10)
            } else if !binding.wrappedValue.isEmpty && !isSearchingSchools {
                VStack(spacing: 15) {
                    Spacer().frame(height: 30)
                    Text("Can't find your school?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button("Use \"\(binding.wrappedValue)\"") {
                        editingEducationField = nil
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.53, green: 0.75, blue: 0.94))
                    .cornerRadius(20)
                }
            }
            
            Spacer()
        }
    }
    
    private func searchSchools(query: String, field: EducationField) {
        let request = MKLocalSearch.Request()
        // 필드에 따라 검색어 보강 (예: 대학교 검색 시 "University" 포함 권장)
        let searchQuery = query.lowercased().contains(field.rawValue.lowercased()) ? query : "\(query) \(field.rawValue) School"
        request.naturalLanguageQuery = searchQuery
        
        // POI 필터링 (학교 관련 건물 위주)
        let filter = MKPointOfInterestFilter(including: [.university, .school])
        request.pointOfInterestFilter = filter
        
        isSearchingSchools = true
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearchingSchools = false
            if let response = response {
                // 이름에 입력값이 포함된 것 위주로 필터링 가능
                self.schoolSuggestions = response.mapItems
            }
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
                        withAnimation {
                            showBonusAlert = true
                        }
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
                } else if !profileImageUrl.isEmpty {
                    AsyncImage(url: URL(string: profileImageUrl)) { image in
                        image.resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())
                    } placeholder: {
                        ProgressView().frame(width: 100, height: 100)
                    }
                } else {
                    Circle().fill(Color.gray.opacity(0.1)).frame(width: 100, height: 100)
                        .overlay(Image(systemName: "camera.fill").foregroundColor(.gray))
                }
            }
            .onChange(of: avatarItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        // 원본 데이터가 아닌 압축된 JPEG 데이터를 사용하여 업로드 속도 및 성공률 개선
                        if let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                            avatarData = compressedData
                            avatarImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
            
            HStack(spacing: 15) {
                labeledField("Last Name", CustomTextField(placeholder: "Last Name", text: $lastName))
                labeledField("First Name", CustomTextField(placeholder: "First Name", text: $firstName))
            }
            labeledField("Nickname", CustomTextField(placeholder: "Nickname", text: $nickname))
            labeledField("Birthday (YYYYMMDD)", CustomTextField(placeholder: "Birthday", text: $birthday)).keyboardType(.numberPad)
            
            labeledField("Address", 
                Button(action: { showAddressSearch = true }) {
                    HStack {
                        Text(address.isEmpty ? "Search Address" : address)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(address.isEmpty ? .gray.opacity(0.5) : .primary)
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(12)
                }
            )
            
            HStack(spacing: 15) {
                labeledField("Gender", setupSelectionField(title: selectedGender == "Select" ? "Select" : selectedGender, field: .gender))
                labeledField("Nationality", setupSelectionField(title: selectedNationality, field: .nationality))
            }
            HStack(spacing: 15) {
                labeledField("Height (cm)", CustomTextField(placeholder: "Height", text: $height)).keyboardType(.numberPad)
                labeledField("Weight (kg)", CustomTextField(placeholder: "Weight", text: $weight)).keyboardType(.numberPad)
            }
            HStack(spacing: 15) {
                labeledField("Blood Type", setupSelectionField(title: selectedBloodType == "Select" ? "Select" : "Type \(selectedBloodType)", field: .blood))
                labeledField("MBTI", setupSelectionField(title: selectedMBTI == "Select" ? "Select" : selectedMBTI, field: .mbti))
            }
        }
    }
    
    var economicsForm: some View {
        VStack(spacing: 15) {
            labeledField("Employment Status", setupSelectionField(title: employmentType == "Select" ? "Select" : employmentType, field: .employment))
            labeledField("Job Field", setupSelectionField(title: jobField == "Select" ? "Select" : jobField, field: .jobField))
            labeledField("Annual Income ($)", CustomTextField(placeholder: "Income", text: $annualIncome)).keyboardType(.numberPad)
            labeledField("Liquid Assets ($)", CustomTextField(placeholder: "Liquid Assets", text: $liquidAssets)).keyboardType(.numberPad)
            labeledField("Fixed Assets ($)", CustomTextField(placeholder: "Fixed Assets", text: $fixedAssets)).keyboardType(.numberPad)
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
            
            // 데이터 업로드 시도
            storageRef.putData(data, metadata: nil) { metadata, error in
                if let error = error {
                    print("Firebase Storage 이미지 업로드 실패: \(error.localizedDescription)")
                    self.updateFirestore(uid: uid, imageUrl: "")
                    return
                }
                
                // URL 가져오기
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Firebase Storage 이미지 URL 가져오기 실패: \(error.localizedDescription)")
                    }
                    self.updateFirestore(uid: uid, imageUrl: url?.absoluteString ?? "")
                }
            }
        } else {
            updateFirestore(uid: uid, imageUrl: "")
        }
    }
    
    func updateFirestore(uid: String, imageUrl: String) {
        let db = Firestore.firestore()
        var updateData: [String: Any] = [
            "lastName": lastName, "firstName": firstName, "nickname": nickname, "birthday": birthday, "gender": selectedGender,
            "nationality": selectedNationality, "height": height, "weight": weight, "bloodType": selectedBloodType,
            "mbti": selectedMBTI, "hobbies": Array(selectedHobbies), "employmentType": employmentType,
            "jobField": jobField, "annualIncome": annualIncome, "liquidAssets": liquidAssets, "fixedAssets": fixedAssets,
            "elementarySchool": elementarySchool, "middleSchool": middleSchool, "highSchool": highSchool,
            "university": university, "graduateSchool": graduateSchool, "isProfileComplete": isAllDone,
            "address": address, "latitude": latitude, "longitude": longitude,
            "mySignBalance": mySignBalance
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
                self.nickname = data["nickname"] as? String ?? ""
                self.birthday = data["birthday"] as? String ?? ""
                self.selectedGender = data["gender"] as? String ?? "Select"
                self.selectedNationality = data["nationality"] as? String ?? "Korea, Republic of"
                self.height = data["height"] as? String ?? ""
                self.weight = data["weight"] as? String ?? ""
                self.selectedBloodType = data["bloodType"] as? String ?? "Select"
                self.selectedMBTI = data["mbti"] as? String ?? "Select"
                self.address = data["address"] as? String ?? ""
                self.latitude = data["latitude"] as? Double ?? 0.0
                self.longitude = data["longitude"] as? Double ?? 0.0
                self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
                
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
                
                if let balance = data["mySignBalance"] as? Int {
                    self.mySignBalance = balance
                }
                
                // 원본 데이터를 백업 (수정 여부 판단용)
                self.originalData = data
            }
        }
    }
    
    private func labeledField<V: View>(_ label: String, _ content: V) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.leading, 4)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Bonus Popup
    private var bonusPopupOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.94))
                
                VStack(spacing: 8) {
                    Text("Bonus Signs Earned!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Your information has been saved.\nYou've been awarded 100 Signs.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    withAnimation {
                        showBonusAlert = false
                    }
                }) {
                    Text("Awesome!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color(red: 0.53, green: 0.75, blue: 0.94))
                        .cornerRadius(15)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(25)
            .padding(.horizontal, 40)
            .shadow(radius: 20)
        }
    }
    
    // MARK: - Confirmation Popups
    
    private var initialConfirmOverlay: some View {
        customConfirmPopup(
            title: "Is the information correct?",
            message: "Is the entered information correct? Once confirmed, 100 Signs will be required for further modifications.",
            buttonTitle: "Finish & Save",
            confirmAction: {
                showInitialConfirm = false
                handleFinalSave()
            },
            cancelAction: { showInitialConfirm = false }
        )
    }
    
    private var editConfirmOverlay: some View {
        customConfirmPopup(
            title: "Check all information?",
            message: "Have you checked all the modified information? 100 Signs are required for profile modification.",
            buttonTitle: "Pay 100 Signs",
            confirmAction: {
                if mySignBalance >= 100 {
                    mySignBalance -= 100
                    showEditConfirm = false
                    handleFinalSave()
                } else {
                    showEditConfirm = false
                    showInsufficientSignsAlert = true
                }
            },
            cancelAction: { showEditConfirm = false }
        )
    }
    
    private var insufficientSignsOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                VStack(spacing: 8) {
                    Text("Insufficient Signs")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("You need at least 100 Signs to modify your profile.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 15) {
                    Button(action: { showInsufficientSignsAlert = false }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(white: 0.95))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        mySignBalance += 500
                        showInsufficientSignsAlert = false
                    }) {
                        Text("Top Up")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(red: 0.53, green: 0.75, blue: 0.94))
                            .cornerRadius(15)
                    }
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(25)
            .padding(.horizontal, 40)
            .shadow(radius: 20)
        }
    }
    
    private func customConfirmPopup(title: String, message: String, buttonTitle: String, confirmAction: @escaping () -> Void, cancelAction: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(message)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 10)
                
                VStack(spacing: 12) {
                    Button(action: confirmAction) {
                        Text(buttonTitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.53, green: 0.75, blue: 0.94))
                            .cornerRadius(15)
                    }
                    
                    Button(action: cancelAction) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(white: 0.95))
                            .cornerRadius(15)
                    }
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
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
