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
