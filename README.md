# Grip Strength Timer App

## General

The Grip Strength Timer app is designed for climbers and athletes who want to improve their grip strength endurance. It provides a convenient way to time hang and rest intervals during grip training sessions. Users can simply start the timer and receive audio cues for when to hang and when to rest, allowing them to focus on their training without needing to constantly check a timer.

## Features

    Simple Interface: The app features a user-friendly interface with a start button to initiate the timer.

    Audio Cues: Users receive audio cues indicating when to start hanging and when to rest, making it easy to follow the training regimen without needing to look at the screen.

    Customizable Intervals: Users can customize the hang and rest intervals according to their training preferences.

## Usage

    Start Timer: Press the start button to initiate the timer.

    Hang: When you hear the audio cue, begin hanging from the designated grip position.

    Rest: After the hang interval, you'll hear another audio cue indicating the start of the rest period. Rest for the specified duration.

    Repeat: Continue hanging and resting according to the audio cues until the timer completes the full sequence.

## Development

### Model

    SoundSequence: Represents a sound cue with a name, duration, and optional start time.

### ViewModel

    TimerViewModel: Manages the timer logic and audio playback.
        startSequence(): Initiates the timer sequence.
        stopSequence(): Stops the timer sequence.
        updateOverallTimer(): Updates the overall timer and plays audio cues.
        startSoundSequence(): Starts playing the sound sequence based on the current index.
        playSound(): Plays a sound file.
        handleInterruption(): Handles interruptions to the audio session.

### Compatibility

    iOS: Compatible with iOS devices running iOS 10.0 and later.
