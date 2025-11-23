////
//// LogsView.swift
//// LiveStreamGPS
////
//
//import SwiftUI
//
//struct LogsView: View {
//    var logs: [String]
//    var onClose: () -> Void
//
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                Text("Logs").foregroundColor(.white).font(.headline)
//                Spacer()
//                Button("Close", action: onClose).foregroundColor(.white)
//            }
//            .padding()
//            .background(Color.black.opacity(0.7))
//
//            ScrollView {
//                VStack(alignment: .leading, spacing: 8) {
//                    ForEach(logs.indices, id: \.self) { i in
//                        Text(logs[i])
//                            .font(.caption2)
//                            .foregroundColor(.white)
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                }.padding()
//            }
//            .background(Color.black.opacity(0.5))
//            .frame(maxHeight: 320)
//        }
//        .background(Color.black.opacity(0.3))
//        .cornerRadius(10)
//        .padding()
//        .edgesIgnoringSafeArea(.bottom)
//    }
//}
//
