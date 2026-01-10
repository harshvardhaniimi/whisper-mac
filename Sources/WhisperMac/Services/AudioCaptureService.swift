import AVFoundation
import Combine

@MainActor
class AudioCaptureService: ObservableObject {
    @Published var audioLevel: Float = 0.0
    @Published var duration: TimeInterval = 0.0
    @Published var isRecording = false

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var recordingStartTime: Date?
    private var levelTimer: Timer?
    private var recordedBuffer: AVAudioPCMBuffer?

    // Store audio samples for processing
    private var audioSamples: [Float] = []

    func requestPermission() async throws -> Bool {
        #if os(macOS)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
        #endif
    }

    func startRecording() async throws {
        let hasPermission = try await requestPermission()
        guard hasPermission else {
            throw AudioError.permissionDenied
        }

        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            throw AudioError.engineInitFailed
        }

        inputNode = engine.inputNode
        guard let input = inputNode else {
            throw AudioError.noInputDevice
        }

        let recordingFormat = input.outputFormat(forBus: 0)

        // Clear previous recording
        audioSamples.removeAll()

        // Install tap on input
        input.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            Task { @MainActor in
                // Calculate audio level
                self.calculateAudioLevel(from: buffer)

                // Store audio samples
                self.appendBuffer(buffer)
            }
        }

        // Start the engine
        try engine.start()

        recordingStartTime = Date()
        isRecording = true

        // Start duration timer
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            Task { @MainActor in
                self.duration = Date().timeIntervalSince(startTime)
            }
        }
    }

    func stopRecording() async -> Data? {
        levelTimer?.invalidate()
        levelTimer = nil

        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()

        isRecording = false
        audioLevel = 0.0

        // Convert stored samples to WAV data
        return createWAVData()
    }

    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        ).map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let normalizedPower = max(0, min(1, (avgPower + 50) / 50))

        audioLevel = normalizedPower
    }

    private func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let samples = Array(UnsafeBufferPointer(start: channelDataValue, count: Int(buffer.frameLength)))
        audioSamples.append(contentsOf: samples)
    }

    private func createWAVData() -> Data? {
        guard !audioSamples.isEmpty else { return nil }

        // Convert to 16-bit PCM
        let sampleRate: UInt32 = 16000 // Whisper expects 16kHz
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16

        // Resample from 48kHz (typical input) to 16kHz
        let resampledSamples = resample(audioSamples, from: 48000, to: 16000)

        // Convert float samples to Int16
        let int16Samples = resampledSamples.map { sample -> Int16 in
            let clampedSample = max(-1.0, min(1.0, sample))
            return Int16(clampedSample * Float(Int16.max))
        }

        // Create WAV file data
        var data = Data()

        // RIFF header
        data.append("RIFF".data(using: .ascii)!)
        let fileSize = UInt32(36 + int16Samples.count * 2)
        data.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        data.append("WAVE".data(using: .ascii)!)

        // fmt chunk
        data.append("fmt ".data(using: .ascii)!)
        data.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // PCM
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        let byteRate = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample) / 8
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        let blockAlign = numChannels * bitsPerSample / 8
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })

        // data chunk
        data.append("data".data(using: .ascii)!)
        let dataSize = UInt32(int16Samples.count * 2)
        data.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })

        for sample in int16Samples {
            data.append(withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }

        return data
    }

    private func resample(_ samples: [Float], from: Int, to: Int) -> [Float] {
        guard from != to else { return samples }

        let ratio = Double(from) / Double(to)
        let outputLength = Int(Double(samples.count) / ratio)
        var output = [Float]()
        output.reserveCapacity(outputLength)

        for i in 0..<outputLength {
            let position = Double(i) * ratio
            let index = Int(position)
            let fraction = Float(position - Double(index))

            if index + 1 < samples.count {
                let sample = samples[index] * (1 - fraction) + samples[index + 1] * fraction
                output.append(sample)
            } else if index < samples.count {
                output.append(samples[index])
            }
        }

        return output
    }
}

enum AudioError: LocalizedError {
    case permissionDenied
    case engineInitFailed
    case noInputDevice

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied. Please enable in System Settings."
        case .engineInitFailed:
            return "Failed to initialize audio engine."
        case .noInputDevice:
            return "No audio input device found."
        }
    }
}
