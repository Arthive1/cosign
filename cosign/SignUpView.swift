import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    
    // Account Info State variables
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var nickname: String = ""
    
    // Profile Info State variables
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: String = ""
    @State private var selectedGender: String = "Select"
    @State private var selectedNationality: String = "Korea, Republic of"
    @State private var selectedHobbies: Set<String> = []
    
    // Profile Image
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var avatarData: Data?
    @State private var fileName: String = "No file selected"
    
    // UI State
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let genders = ["Male", "Female"]
    let nationalities = ["Korea, Republic of", "USA", "Japan", "China", "United Kingdom", "France", "Germany", "Canada", "Australia"]
    let hobbies = [
        ("Sports", "figure.run"),
        ("Instrument", "music.note"),
        ("Game", "gamecontroller"),
        ("Reading", "book")
    ]
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 25) {
                    // Section 1: Account Info
                    VStack(spacing: 15) {
                        CustomTextField(placeholder: "Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                            .cornerRadius(12)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                            .cornerRadius(12)
                        
                        CustomTextField(placeholder: "Nickname", text: $nickname)
                    }
                    
                    // Section 2: Profile Picture
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Profile Picture")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(fileName)
                                .font(.system(size: 14))
                                .foregroundColor(avatarImage == nil ? .secondary : .primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            PhotosPicker(selection: $avatarItem, matching: .images) {
                                Text("Choose File")
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.9, green: 0.9, blue: 0.94))
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.4))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                        .cornerRadius(12)
                        
                        if let avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.05), lineWidth: 1))
                        }
                    }
                    .onChange(of: avatarItem) { oldValue, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                if let uiImage = UIImage(data: data) {
                                    avatarData = data
                                    avatarImage = Image(uiImage: uiImage)
                                    fileName = "profile_image.jpg"
                                }
                            }
                        }
                    }
                    
                    // Section 3: Personal Info
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            CustomTextField(placeholder: "Last Name", text: $lastName)
                            CustomTextField(placeholder: "First Name", text: $firstName)
                        }
                        
                        CustomTextField(placeholder: "Birthday (YYYYMMDD)", text: $birthday)
                            .keyboardType(.numberPad)
                        
                        HStack(spacing: 15) {
                            Menu {
                                ForEach(genders, id: \.self) { gender in
                                    Button(gender) { selectedGender = gender }
                                }
                            } label: {
                                HStack {
                                    Text(selectedGender == "Select" ? "Gender" : selectedGender)
                                        .foregroundColor(selectedGender == "Select" ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                                .cornerRadius(12)
                            }
                            
                            Menu {
                                ForEach(nationalities, id: \.self) { nation in
                                    Button(nation) { selectedNationality = nation }
                                }
                            } label: {
                                HStack {
                                    Text(selectedNationality)
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Section 4: Hobbies
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hobbies")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(hobbies, id: \.0) { hobby, icon in
                                HobbyButton(title: hobby, icon: icon, isSelected: selectedHobbies.contains(hobby)) {
                                    if selectedHobbies.contains(hobby) {
                                        selectedHobbies.remove(hobby)
                                    } else {
                                        selectedHobbies.insert(hobby)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Complete Button
                    Button(action: {
                        handleSignUp()
                    }) {
                        Text("Complete")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.67, green: 0.82, blue: 0.94))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
            }
            .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView("Creating Account...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("Sign Up", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage == "Successfully registered!" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Validation & SignUp Logic
    func handleSignUp() {
        // 1. Basic Validation
        guard !email.isEmpty, !password.isEmpty, !nickname.isEmpty else {
            alertMessage = "Please fill in all account fields."
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // 2. Create User in Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                isLoading = false
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            // 3. Upload Image to Firebase Storage if exists
            if let data = avatarData {
                let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
                storageRef.putData(data, metadata: nil) { metadata, error in
                    if let error = error {
                        print("Storage Error: \(error.localizedDescription)")
                        // Continue even if image fails, or handle error
                    }
                    
                    storageRef.downloadURL { url, error in
                        saveUserData(uid: uid, profileImageUrl: url?.absoluteString ?? "")
                    }
                }
            } else {
                saveUserData(uid: uid, profileImageUrl: "")
            }
        }
    }
    
    func saveUserData(uid: String, profileImageUrl: String) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "nickname": nickname,
            "lastName": lastName,
            "firstName": firstName,
            "birthday": birthday,
            "gender": selectedGender,
            "nationality": selectedNationality,
            "hobbies": Array(selectedHobbies),
            "profileImageUrl": profileImageUrl,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                alertMessage = "Successfully registered!"
                showAlert = true
            }
        }
    }
}

// Custom UI Components
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
            .cornerRadius(12)
            .font(.system(size: 16, weight: .medium, design: .rounded))
    }
}

struct HobbyButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(red: 0.96, green: 0.76, blue: 0.76) : Color(red: 0.96, green: 0.96, blue: 0.98))
            .foregroundColor(isSelected ? .white : Color(red: 0.4, green: 0.4, blue: 0.5))
            .cornerRadius(10)
            .animation(.spring(), value: isSelected)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
