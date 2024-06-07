import SwiftUI
import AVFoundation
import UserNotifications

struct SoundSequence {
    let name: String
    let duration: Double
    let startTime: TimeInterval?
}
extension SoundSequence: Equatable {
    static func ==(lhs: SoundSequence, rhs: SoundSequence) -> Bool {
        return lhs.name == rhs.name &&
               lhs.duration == rhs.duration &&
               lhs.startTime == rhs.startTime
    }
}

class TimerViewModel: ObservableObject {
    @Published var isTimerRunning = false
    @Published var secondsPassed = 0 // Published to bind with the view

    private var activityTimer: Timer?
    private var breakTimer: Timer?
    private var initialDelayTimer: Timer?
    private var overallTimer: Timer?
    private var isActivityTime = true
    private var currentSoundIndex = 0

    let totalDuration = 60
    let initialDelay = 3

    // Define the sequences
    let initialSequence: [SoundSequence] = [
        SoundSequence(name: "321beep", duration: 3, startTime: nil)
    ]
    let activitySequence: [SoundSequence] = [
        SoundSequence(name: "10brazil", duration: 8, startTime: nil),
        SoundSequence(name: "beep", duration: 0.66, startTime: nil),
        SoundSequence(name: "beep", duration: 0.66, startTime: nil),
        SoundSequence(name: "beep", duration: 0.66, startTime: nil)


        
    ]

    private var audioPlayer: AVAudioPlayer?

    init() {
        // Observe audio session interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
                self.scheduleTestNotification() // Test notification permission
            }
        }
    }

    private func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification to check if permissions work."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to add test notification: \(error)")
            } else {
                print("Test notification scheduled successfully.")
            }
        }
    }

    // Function to start the sequence
    func startSequence() {
        if !isTimerRunning {
            // Set up audio session for background playback
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set up audio session: \(error)")
            }

            isTimerRunning = true
            secondsPassed = 0
            isActivityTime = true
            currentSoundIndex = 0
            print("Starting sequence. Initial time: \(secondsPassed) seconds")

            startInitialDelay()
        }
    }

    // Function to stop the sequence
    func stopSequence() {
        isTimerRunning = false
        activityTimer?.invalidate()
        breakTimer?.invalidate()
        initialDelayTimer?.invalidate()
        overallTimer?.invalidate()
        audioPlayer?.stop() // Stop the audio player
        print("Sequence stopped. Final time: \(secondsPassed) seconds")
    }

    private func startOverallTimer() {
        overallTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateOverallTimer), userInfo: nil, repeats: true)
    }

    @objc private func updateOverallTimer() {
        if secondsPassed < totalDuration {
            secondsPassed += 1
            print("Overall timer updated: \(secondsPassed) seconds")

            // Play beep three times on second 57
            if secondsPassed == 58 {
                overallTimer?.invalidate()
                isTimerRunning = false
            
                self.playSound(name: "stop")

                print("Sequence completed. Total time: \(secondsPassed) seconds")
                scheduleNotification(title: "Timer Completed", body: "The timer has completed its full sequence.", in: 1)
       
               // stopSequence() // Stop the sequence after playing the beeps
            }
        } 
    }

    private func startSoundSequence(sequence: [SoundSequence]) {
        if currentSoundIndex < sequence.count {
            let sound = sequence[currentSoundIndex]
            
            // Case 1: Sound has a specific start time
            if let startTime = sound.startTime {
                if sound.name == "10brazil" {
                    playSoundSegmentWithRate(name: sound.name, from: startTime, duration: TimeInterval(sound.duration), rate: 1.25) // Adjust rate for "10brazil"
                } else {
                    playSoundSegment(name: sound.name, from: startTime, duration: TimeInterval(sound.duration))
                }
            } else {
                // Case 2: Sound plays from the beginning (no start time)
                if sound.name == "10brazil" {
                    playSoundSegmentWithRate(name: sound.name, from: 0, duration: TimeInterval(sound.duration), rate: 1.25) // Adjust rate for "10brazil"
                } else {
                    playSound(name: sound.name)
                }
            }
            
            // Schedule the timer for the sound duration
            activityTimer = Timer.scheduledTimer(timeInterval: TimeInterval(sound.duration), target: self, selector: #selector(soundSequenceEnded), userInfo: sequence, repeats: false)
        }
    }

    private func startInitialDelay() {
        initialDelayTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateInitialDelay), userInfo: nil, repeats: true)
        playSoundSegment(name: "beep", from: 1, duration: TimeInterval(3))
        
    }

    @objc private func updateInitialDelay() {
        if secondsPassed < initialDelay {
            secondsPassed += 1
            print("Initial delay: \(secondsPassed) seconds")
        } else {
            initialDelayTimer?.invalidate()
            secondsPassed = 0
            print("Initial delay ended. Starting get ready sequence.")
            startSoundSequence(sequence: initialSequence)
        }
    }
    
    private func playSoundSegmentWithRate(name: String, from startTime: TimeInterval, duration: TimeInterval, rate: Float) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = rate
            audioPlayer?.currentTime = startTime
            audioPlayer?.play()
            print("Playing sound: \(name) from \(startTime) for \(duration) seconds at rate \(rate)")
            
            // Stop the audio after the specified duration
            DispatchQueue.main.asyncAfter(deadline: .now() + (duration / Double(rate))) { [weak self] in
                self?.audioPlayer?.stop()
            }
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    func resetTimer() {
        stopSequence()
        secondsPassed = 0
        print("Resetting timer")
    }

    @objc private func soundSequenceEnded(_ timer: Timer) {
        currentSoundIndex += 1
        if let sequence = timer.userInfo as? [SoundSequence] {
            if currentSoundIndex < sequence.count {
                startSoundSequence(sequence: sequence)
            } else {
                if sequence == initialSequence {
                    currentSoundIndex = 0
                    print("Get ready sequence ended. Starting main sequence.")
                    startSoundSequence(sequence: activitySequence)
                    startOverallTimer()
                } else if isActivityTime {
                    if currentSoundIndex < activitySequence.count {
                        startSoundSequence(sequence: activitySequence)
                    } else {
                        isActivityTime = false
                        currentSoundIndex = 0
                        startSoundSequence(sequence: activitySequence)
                        print("Activity sequence ended. Starting break sequence.")
                        scheduleNotification(title: "Break Time", body: "The activity period has ended. Starting break.", in: 1)
                    }
                } else {
                    if currentSoundIndex < activitySequence.count {
                        startSoundSequence(sequence: activitySequence)
                    } else {
                        isActivityTime = true
                        currentSoundIndex = 0
                        startSoundSequence(sequence: activitySequence)
                        print("Break sequence ended. Switching to activity sequence.")
                        scheduleNotification(title: "Activity Time", body: "The break period has ended. Starting activity.", in: 1)
                    }
                }
            }
        }
    }

    private func playSound(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            print("Playing sound: \(name)")
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    private func playSoundSegment(name: String, from startTime: TimeInterval, duration: TimeInterval) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.currentTime = startTime
            audioPlayer?.play()
            print("Playing sound: \(name) from \(startTime) for \(duration) seconds")
            
            // Stop the audio after the specified duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.audioPlayer?.stop()
            }
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            // Interruption began, pause the timer
            print("Audio session interrupted, pausing timer")
        } else if type == .ended {
            // Interruption ended, resume the timer
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("Audio session interruption ended")
            } catch {
                print("Failed to reactivate audio session: \(error)")
            }
        }
    }

    private func scheduleNotification(title: String, body: String, in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to add notification: \(error)")
            } else {
                print("Notification scheduled successfully: \(title) - \(body)")
            }
        }
    }
}
