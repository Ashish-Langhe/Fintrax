//
//  FinnyVoiceIOService.swift
//  Fintrax
//
//  Fintrax documentation: Handles Finny voice input, speech recognition, and spoken responses.
//

import AVFoundation
import Speech

@MainActor
final class FinnyVoiceIOService: NSObject, ObservableObject {
    enum VoiceState: Equatable {
        case idle
        case requestingPermission
        case listening
        case unavailable(String)
    }

    @Published private(set) var state: VoiceState = .idle
    @Published private(set) var transcript = ""

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_IN"))
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var isListening: Bool {
        state == .listening
    }

    func startListening() async {
        guard !isListening else { return }

        state = .requestingPermission
        let isAuthorized = await requestPermissions()
        guard isAuthorized else {
            state = .unavailable(L10n.string("assistant.voice.permissionDenied"))
            return
        }

        do {
            try startRecognitionSession()
            state = .listening
        } catch {
            stopListening()
            ErrorLogger.log(error, context: "FinnyVoiceIOService.startListening")
            state = .unavailable(L10n.string("assistant.voice.startFailed"))
        }
    }

    func stopListening() {
        finishRecognitionSession(cancelRecognition: false)
    }

    private func cancelListening() {
        finishRecognitionSession(cancelRecognition: true)
    }

    private func finishRecognitionSession(cancelRecognition: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        if cancelRecognition {
            recognitionTask?.cancel()
        } else {
            recognitionRequest?.endAudio()
        }

        recognitionTask = nil
        recognitionRequest = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        if state == .listening || state == .requestingPermission {
            state = .idle
        }
    }

    func resetTranscript() {
        transcript = ""
    }

    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
            ?? AVSpeechSynthesisVoice(language: "en-IN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.02
        speechSynthesizer.speak(utterance)
    }

    private func requestPermissions() async -> Bool {
        let speech = await requestSpeechPermission()
        let microphone = await requestMicrophonePermission()
        return speech && microphone
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func startRecognitionSession() throws {
        cancelListening()
        transcript = ""

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceRecognitionError.recognizerUnavailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self.finishRecognitionSession(cancelRecognition: false)
                }
            }
        }
    }
}

private enum VoiceRecognitionError: Error {
    case recognizerUnavailable
}
