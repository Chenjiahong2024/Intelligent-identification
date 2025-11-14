import SwiftUI

struct PermissionsStatusView: View {
    @State private var dummyCompletion = false
    
    var body: some View {
        PermissionsOnboardingView(
            isCompleted: $dummyCompletion,
            mode: .review
        )
        .navigationTitle("权限状态")
        .navigationBarTitleDisplayMode(.inline)
    }
}

