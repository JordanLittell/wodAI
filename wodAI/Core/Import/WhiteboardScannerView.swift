//
//  WhiteboardScannerView.swift
//  wodAI
//
//  Full-screen camera for importing a workout from a gym whiteboard. Live
//  text recognition runs on the phone; once what it reads looks like a
//  workout and holds steady for a moment, it takes the photo and closes by
//  itself. Where the live camera isn't available (the Simulator, older
//  phones, camera access denied) it offers a photo from the library instead.
//

import AVFoundation
import PhotosUI
import SwiftUI
import Vision
import VisionKit

struct WhiteboardScannerView: View {
    /// Called once with the photo to import; the view has already been
    /// asked to close.
    let onCapture: (WhiteboardCapture) -> Void
    @Environment(\.dismiss) private var dismiss

    private enum Mode: Equatable {
        case checking
        case camera
        case library(reason: String)
    }

    @State private var mode: Mode = .checking
    @State private var looksReady = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch mode {
            case .checking:
                ProgressView().tint(.white)
            case .camera:
                LiveTextScanner(
                    onReadinessChange: { ready in
                        withAnimation(.easeInOut(duration: 0.2)) { looksReady = ready }
                    },
                    onCapture: finish
                )
                .ignoresSafeArea()
                cameraOverlay
            case let .library(reason):
                WhiteboardPhotoPicker(reason: reason, onCapture: finish)
            }
        }
        .overlay(alignment: .topLeading) {
            Button("Cancel") { dismiss() }
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.45)))
                .padding()
        }
        .task { mode = await Self.availableMode() }
    }

    private var cameraOverlay: some View {
        VStack {
            Spacer()
            Label(
                looksReady ? "Got it, hold steady" : "Point at the whiteboard",
                systemImage: looksReady ? "checkmark.circle.fill" : "camera.viewfinder"
            )
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(looksReady ? Color("Success").opacity(0.85) : Color.black.opacity(0.55)))
            .padding(.bottom, 40)
            .contentTransition(.opacity)
        }
        .allowsHitTesting(false)
    }

    private func finish(_ capture: WhiteboardCapture) {
        dismiss()
        onCapture(capture)
    }

    /// The live camera when this device has it and camera access is (or
    /// becomes) allowed; otherwise the photo library, with why.
    @MainActor
    private static func availableMode() async -> Mode {
        guard DataScannerViewController.isSupported else {
            return .library(reason: "Live scanning isn't available on this device. Choose a photo of the whiteboard instead.")
        }
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        guard DataScannerViewController.isAvailable else {
            return .library(reason: "Camera access is off for wodAI. Turn it on in Settings, or choose a photo of the whiteboard instead.")
        }
        return .camera
    }
}

// MARK: - Live camera

/// VisionKit's live text scanner, watching for text that reads like a workout.
private struct LiveTextScanner: UIViewControllerRepresentable {
    let onReadinessChange: (Bool) -> Void
    let onCapture: (WhiteboardCapture) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        guard !scanner.isScanning else { return }
        try? scanner.startScanning()
        context.coordinator.startWatching()
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        coordinator.stopWatching()
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onReadinessChange: onReadinessChange, onCapture: onCapture)
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        weak var scanner: DataScannerViewController?
        private let onReadinessChange: (Bool) -> Void
        private let onCapture: (WhiteboardCapture) -> Void
        private var gate = WhiteboardStabilityGate()
        private var lines: [String] = []
        private var looksReady = false
        private var isCapturing = false
        private var timer: Timer?

        init(onReadinessChange: @escaping (Bool) -> Void, onCapture: @escaping (WhiteboardCapture) -> Void) {
            self.onReadinessChange = onReadinessChange
            self.onCapture = onCapture
        }

        /// Checks the hold on a timer as well as on each update: a still
        /// board sends no updates, and it should still be captured.
        func startWatching() {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.check() }
            }
        }

        func stopWatching() {
            timer?.invalidate()
            timer = nil
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            read(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            read(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            read(allItems)
        }

        private func read(_ items: [RecognizedItem]) {
            lines = items.compactMap { item in
                if case let .text(text) = item { return text.transcript }
                return nil
            }
            gate.update(passes: WhiteboardHeuristic.looksLikeWorkout(lines: lines), at: Date())
            check()
        }

        private func check() {
            let passing = gate.passingSince != nil
            if passing != looksReady {
                looksReady = passing
                onReadinessChange(passing)
            }
            guard !isCapturing, gate.isSatisfied(at: Date()) else { return }
            capture()
        }

        private func capture() {
            guard let scanner else { return }
            isCapturing = true
            stopWatching()
            let text = lines.joined(separator: "\n")
            Task { @MainActor in
                do {
                    let photo = try await scanner.capturePhoto()
                    guard let jpeg = WhiteboardImageEncoder.jpeg(from: photo) else { throw CaptureError.encoding }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onCapture(WhiteboardCapture(jpeg: jpeg, recognizedText: text))
                } catch {
                    // Keep scanning and try again on the next steady read.
                    TelemetryService.captureError(error, tags: ["operation": "WhiteboardCapture"])
                    gate = WhiteboardStabilityGate()
                    isCapturing = false
                    startWatching()
                }
            }
        }

        private enum CaptureError: Error {
            case encoding
        }
    }
}

// MARK: - Photo library fallback

/// Picks a photo of a whiteboard, reads its text on the phone, and imports
/// it. A photo that doesn't read like a workout can still be sent; the
/// server has the final say.
private struct WhiteboardPhotoPicker: View {
    let reason: String
    let onCapture: (WhiteboardCapture) -> Void

    @State private var item: PhotosPickerItem?
    @State private var isReading = false
    /// A photo that didn't pass the on-device check, held for "Use anyway".
    @State private var doubtful: WhiteboardCapture?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.8))
            Text(reason)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            if isReading {
                ProgressView().tint(.white)
            } else {
                PhotosPicker(selection: $item, matching: .images) {
                    Label("Choose a photo", systemImage: "photo")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.brandPrimary))
                        .foregroundColor(.white)
                }
            }

            if let doubtful {
                VStack(spacing: 10) {
                    Text("That photo doesn't look like a workout.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("Warning"))
                    Button("Use it anyway") { onCapture(doubtful) }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(Color("Error"))
            }
        }
        .padding(32)
        .onChange(of: item) { _, newItem in
            guard let newItem else { return }
            Task { await read(newItem) }
        }
    }

    private func read(_ item: PhotosPickerItem) async {
        isReading = true
        doubtful = nil
        errorMessage = nil
        defer { isReading = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = WhiteboardImageEncoder.jpeg(from: image)
        else {
            errorMessage = "Couldn't open that photo."
            return
        }
        let lines = await Self.recognizeText(in: image)
        let capture = WhiteboardCapture(jpeg: jpeg, recognizedText: lines.joined(separator: "\n"))
        if WhiteboardHeuristic.looksLikeWorkout(lines: lines) {
            onCapture(capture)
        } else {
            doubtful = capture
        }
    }

    /// The photo's text lines, read with Vision; empty if it can't be read.
    private static func recognizeText(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .init(image.imageOrientation))
            try? handler.perform([request])
            return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        }.value
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
