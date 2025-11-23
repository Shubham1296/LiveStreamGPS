////
////  EditURLView.swift
////  LiveStreamGPS
////
//
//import SwiftUI
//
//struct EditURLView: View {
//    @Binding var isPresented: Bool
//    @ObservedObject private var server = ServerConfig.shared
//    @State private var tempURL: String = ""
//
//    init(isPresented: Binding<Bool>) {
//        self._isPresented = isPresented
//        self._tempURL = State(initialValue: ServerConfig.shared.wsURL)
//    }
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 16) {
//
//                Text("WebSocket Server URL")
//                    .font(.headline)
//                    .padding(.top, 10)
//
//                TextField("wss://4928ba6f960f.ngrok-free.app/ws", text: $tempURL)
//                    .textFieldStyle(.roundedBorder)
//                    .disableAutocorrection(true)
//                    .autocapitalization(.none)
//                    .padding(.horizontal)
//
//                Spacer()
//
//                Button {
//                    let cleaned = tempURL.trimmingCharacters(in: .whitespacesAndNewlines)
//                    server.wsURL = cleaned
//
//                    // Notify WS client that the URL changed
//                    NotificationCenter.default.post(
//                        name: NSNotification.Name("ServerURLChanged"),
//                        object: nil
//                    )
//
//                    isPresented = false
//                } label: {
//                    Text("Save & Close")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.borderedProminent)
//                .padding(.horizontal)
//                .padding(.bottom, 20)
//            }
//            .navigationBarTitle("Edit URL", displayMode: .inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Close") {
//                        isPresented = false
//                    }
//                }
//            }
//        }
//    }
//}
//
