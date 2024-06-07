import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = TimerViewModel()

    var body: some View {
        ZStack {
            Image("backgroundImage") // Replace with your image name
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Timer: \(viewModel.secondsPassed)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()

                HStack {
                    Button(action: {
                        viewModel.startSequence()
                    }) {
                        Text("Start")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.stopSequence()
                    }) {
                        Text("Stop")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        viewModel.resetTimer()
                    }) {
                        Text("Reset")
                            .padding()
                            .background(viewModel.isTimerRunning ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.isTimerRunning)
                }
                .padding()
            }
        }
    }
}
