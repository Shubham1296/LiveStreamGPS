import SwiftUI

struct BackupListView: View {

    @ObservedObject var backup = BackupService.shared

    var body: some View {
        NavigationView {
            List(backup.savedEntries, id: \.self) { entry in
                Text(entry)
            }
            .navigationTitle("Saved Backups")
        }
    }
}
