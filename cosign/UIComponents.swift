import SwiftUI

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

// MARK: - Profile Comparison Components
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
            
            VStack(alignment: .leading, spacing: 12) {
                InfoLabel(text: data["nickname"] as? String ?? "User", icon: "person", isBold: true)
                InfoLabel(text: String((data["birthday"] as? String ?? "Unknown").prefix(4)), icon: "calendar")
                InfoLabel(text: "\(data["height"] as? String ?? "0")cm", icon: "ruler")
                InfoLabel(text: "\(data["weight"] as? String ?? "0")kg", icon: "scalemass")
                InfoLabel(text: data["mbti"] as? String ?? "None", icon: "brain")
                
                HStack(spacing: 6) {
                    Image(systemName: "graduationcap")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(getHighestEdu(data))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 35) // 프로필 사진 정렬에 맞춰 패딩 조정
            .padding(.bottom, 20)
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
