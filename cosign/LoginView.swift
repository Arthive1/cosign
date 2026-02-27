import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // 이 함수의 결과로 로그인이 성공하면 ContentView에서 MainView로 화면을 전환할 것입니다.
    var onLoginSuccess: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 25) {
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .padding(.top, 40)
                    
                    VStack(spacing: 15) {
                        TextField("Email Address", text: $email)
                            .padding()
                            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                            .cornerRadius(12)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        handleLogin()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Log in")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.67, green: 0.82, blue: 0.94))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 20)
                    .disabled(isLoading)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Login", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    func handleLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please enter your email and password."
            showAlert = true
            return
        }
        
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                dismiss() // 팝업 닫기
                onLoginSuccess() // 성공 콜백 호출
            }
        }
    }
}

#Preview {
    LoginView(onLoginSuccess: {})
}
