import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    
    // Account Info State variables
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var nickname: String = ""
    
    // UI State
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        
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
                    }
                    
                    // Complete Button
                    Button(action: {
                        handleSignUp()
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.67, green: 0.82, blue: 0.94))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                    .padding(.top, 10)
                    .disabled(isLoading)
                    
                    Text("By signing up, you agree to our Terms and Conditions.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.horizontal, 30)
                .padding(.top, 40)
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
        .navigationTitle("Create Account")
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
        guard !email.isEmpty, !password.isEmpty, !nickname.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                isLoading = false
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            
            guard let uid = result?.user.uid else { return }
            saveUserData(uid: uid)
        }
    }
    
    func saveUserData(uid: String) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "nickname": nickname,
            "isProfileComplete": false, // 프로필 설정 여부 체크용
            "mySignBalance": 0,
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

// Custom UI Components 삭제됨 (UIComponents.swift로 이동)

#Preview {
    NavigationStack {
        SignUpView()
    }
}
