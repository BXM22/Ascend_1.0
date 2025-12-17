import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .imageScale(.large)
                    .font(.system(size: 48))
                Text("Workout Tracker")
                    .font(.title.bold())
                Text("Welcome! This is a placeholder ContentView. Replace this with your real home screen.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
