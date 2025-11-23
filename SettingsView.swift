import SwiftUI

struct SettingsView: View {
    @Binding var serverURL: String
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Server Settings")
                .foregroundColor(.white)
                .font(.title2)

            TextField("https://xxxxx.ngrok-free.app", text: $serverURL)
                .textFieldStyle(.roundedBorder)
                .padding()
                .background(.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)

            Button("Save & Close") {
                onClose()
            }
            .padding()
            .foregroundColor(.white)
            .background(.blue.opacity(0.5))
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: 350)
        .background(.black.opacity(0.8))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

