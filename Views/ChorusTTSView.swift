import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import AVFoundation
import UIKit

struct ChorusTTSView: View {
    
    // File Picker
    @State private var isImporterPresented = false
    @State private var selectedFileName: String?
    @State private var data: Data?
    @State private var displayedText: String?
    
    // TTS Component
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var isSpeaking = false
    @State private var isPaused = false
    
    // Text appearance
    @State private var textSize: CGFloat = 18
    
    // Speech progress and highlighting
    @State private var currentSpokenRange: NSRange?
    @State private var fullTextLength: Int = 1
    @State private var speechBaseOffset: Int = 0 // where the current utterance starts in the full text
    @State private var speechProgress: Double = 0.0
    @State private var isScrubbing = false
    @State private var speechDelegate = SpeechDelegate()
    
    var body: some View {
        
        ZStack {
            // MARK: - BACKGROUND
            backgroundLayers
            
            // MARK: - FILE PICKER BUTTON (HIDES AFTER SELECTION)
            if selectedFileName == nil {
                VStack {
                    Button(action: {
                        isImporterPresented = true
                    }) {
                        Text("Select File")
                            .font(.headline)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(.gray)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .zIndex(3)
            }
            
            // MARK: - DISPLAYED TEXT BOX (CENTERED)
            if let text = displayedText {
                VStack(spacing: 16) {
                    Spacer()

                    // ---------------------------
                    //  Glass Text Box
                    // ---------------------------
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(radius: 10)

                        // UITextView-backed view that highlights and autoscrolls, and supports tap-to-seek
                        AttributedTextView(
                            text: text,
                            fontSize: textSize,
                            highlightRange: currentSpokenRange,
                            onTapAtIndex: { tappedIndex in
                                // Jump to tapped word and resume speaking from there
                                seek(to: tappedIndex, autoResume: true)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding()
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.85,
                           height: UIScreen.main.bounds.height * 0.75)
                    // Stepper overlay for text size control
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 12) {
                            Text("Text size: \(Int(textSize)) pt")
                                .foregroundColor(.white)
                                .font(.footnote)
                            Stepper("", value: $textSize, in: 12...36, step: 1)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .tint(.white)
                        .padding(12)
                    }

                    // Interactive progress bar (scrub to seek)
                    Slider(value: Binding(
                        get: { speechProgress },
                        set: { newVal in
                            speechProgress = newVal
                        }
                    ), in: 0...1, onEditingChanged: { editing in
                        isScrubbing = editing
                        if editing {
                            // Pause while scrubbing to avoid drift
                            pauseSpeaking()
                        } else {
                            // Seek to the selected fraction and resume
                            seekToFraction(speechProgress)
                        }
                    })
                    .tint(.white)
                    .frame(width: UIScreen.main.bounds.width * 0.85)
                    .opacity(displayedText == nil ? 0 : 1)

                    // ---------------------------
                    //  TTS BUTTONS
                    // ---------------------------
                    HStack(spacing: 20) {
                        Button(action: {
                            // Start from current highlight if present, else from beginning
                            let startIndex = currentSpokenRange?.location ?? 0
                            startSpeaking(from: startIndex)
                        }) {
                            Text("Speak")
                                .font(.headline)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.black)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            if isPaused {
                                resumeSpeaking()
                            } else {
                                pauseSpeaking()
                            }
                        }) {
                            Text(isPaused ? "Resume" : "Pause")
                                .font(.headline)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            stopSpeaking()
                        }) {
                            Text("Stop")
                                .font(.headline)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }

                    Spacer()
                }
                .transition(.opacity)
                .zIndex(4)
            }
        }
        .onAppear {
            // Hook up the delegate once
            synthesizer.delegate = speechDelegate
            
            speechDelegate.onStart = { _ in
                DispatchQueue.main.async {
                    self.isSpeaking = true
                    self.isPaused = false
                }
            }
            speechDelegate.onRange = { range, _ in
                DispatchQueue.main.async {
                    // Convert local utterance range to global range
                    let globalLocation = self.speechBaseOffset + range.location
                    self.currentSpokenRange = NSRange(location: globalLocation, length: range.length)
                    
                    // Progress across the full text
                    let done = min(globalLocation + range.length, max(1, self.fullTextLength))
                    self.speechProgress = Double(done) / Double(max(1, self.fullTextLength))
                }
            }
            speechDelegate.onFinish = { _ in
                DispatchQueue.main.async {
                    self.isSpeaking = false
                    self.isPaused = false
                    // keep progress at current value; if truly finished, it will be 1.0
                }
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    
    // MARK: - Background layers extracted for clarity
    var backgroundLayers: some View {
        MenuCirclelessView()
            .ignoresSafeArea()
    }
    
    // MARK: - Build a header listing available voices
    func voicesHeader() -> String {
        let lines = AVSpeechSynthesisVoice.speechVoices()
            .map { "\($0.name) (\($0.identifier))" }
            .sorted()
        return """
        Available Voices (\(lines.count)):
        \(lines.joined(separator: "\n"))

        """
    }
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let fileURL = try result.get().first else { return }
            selectedFileName = fileURL.lastPathComponent
            
            // IMPORTANT: Access the security-scoped file
            guard fileURL.startAccessingSecurityScopedResource() else {
                print("Could not access security-scoped URL")
                return
            }
            defer { fileURL.stopAccessingSecurityScopedResource() }
            
            // Load data safely
            data = try Data(contentsOf: fileURL)
            
            // Try plain text first
            if let text = String(data: data!, encoding: .utf8) {
                displayedText = text
                resetSpeechStateForNewText(text)
                return
            }
            
            // If PDF, extract with PDFKit
            if fileURL.pathExtension.lowercased() == "pdf" {
                let text = extractPDFText(from: fileURL)
                displayedText = text
                resetSpeechStateForNewText(text)
                return
            }
            
            displayedText = "(Unable to read file contents.)"
            resetSpeechStateForNewText(displayedText ?? "")
            
        } catch {
            print("Import failed: \(error.localizedDescription)")
        }
    }
    
    private func resetSpeechStateForNewText(_ text: String) {
        let ns = text as NSString
        fullTextLength = ns.length
        speechBaseOffset = 0
        currentSpokenRange = nil
        speechProgress = 0
        isSpeaking = false
        isPaused = false
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - PDF TEXT EXTRACTION
    func extractPDFText(from url: URL) -> String {
        guard let pdf = PDFDocument(url: url) else { return "(Unable to open PDF.)" }
        
        var extracted = ""
        for i in 0 ..< pdf.pageCount {
            if let page = pdf.page(at: i),
               let text = page.string {
                extracted += text + "\n\n"
            }
        }
        return extracted.isEmpty ? "(PDF contains no readable text.)" : extracted
    }
    
    // MARK: - Speaking control
    private func startSpeaking(from startIndex: Int) {
        guard let fullText = displayedText else { return }
        let ns = fullText as NSString
        let boundedStart = max(0, min(startIndex, max(0, ns.length - 1)))
        
        // Stop any current speech
        synthesizer.stopSpeaking(at: .immediate)
        isPaused = false
        
        // Start a new utterance from the requested position (snap to word boundary)
        let snappedStart = wordStart(in: ns, around: boundedStart)
        let substring = ns.substring(from: snappedStart)
        
        speechBaseOffset = snappedStart
        currentSpokenRange = NSRange(location: snappedStart, length: 0)
        
        let utterance = AVSpeechUtterance(string: substring)
        // Choose a reasonable voice available on the device/simulator
        let preferred = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "en-US" }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
            .first
        utterance.voice = preferred ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.05
        utterance.postUtteranceDelay = 0.2
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    private func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            isPaused = true
        }
    }
    
    private func resumeSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
            isSpeaking = true
        }
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentSpokenRange = nil
    }
    
    // MARK: - Seeking
    private func seekToFraction(_ fraction: Double) {
        guard let fullText = displayedText else { return }
        let ns = fullText as NSString
        let f = max(0, min(1, fraction))
        let target = Int((Double(ns.length) * f).rounded())
        seek(to: target, autoResume: true)
    }
    
    private func seek(to index: Int, autoResume: Bool) {
        // If currently speaking or paused, restart from the requested position
        startSpeaking(from: index)
        if !autoResume {
            pauseSpeaking()
        }
    }
    
    // Snap to the beginning of the word at/near index
    private func wordStart(in ns: NSString, around index: Int) -> Int {
        if ns.length == 0 { return 0 }
        let whitespaces = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        var i = max(0, min(index, ns.length - 1))
        // Move backward while current char is not a delimiter
        while i > 0 {
            let c = ns.character(at: i)
            if let scalar = UnicodeScalar(c), whitespaces.contains(scalar) {
                return min(ns.length - 1, i + 1)
            }
            i -= 1
        }
        return 0
    }
}

// MARK: - AVSpeechSynthesizer delegate bridge
final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onRange: ((NSRange, AVSpeechUtterance) -> Void)?
    var onStart: ((AVSpeechUtterance) -> Void)?
    var onFinish: ((AVSpeechUtterance) -> Void)?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        onRange?(characterRange, utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didStart utterance: AVSpeechUtterance) {
        onStart?(utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        onFinish?(utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        onFinish?(utterance)
    }
}

// MARK: - UITextView-backed view for attributed text, highlighting, autoscroll, and tap-to-seek
struct AttributedTextView: UIViewRepresentable {
    var text: String
    var fontSize: CGFloat
    var highlightRange: NSRange?
    var onTapAtIndex: ((Int) -> Void)? = nil
    
    class Coordinator: NSObject {
        weak var textView: UITextView?
        var onTap: ((Int) -> Void)?
        var lastText: String = ""
        var lastFontSize: CGFloat = 0
        var lastHighlight: NSRange?
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let tv = textView else { return }
            var location = gesture.location(in: tv)
            // Convert to text container coordinates
            location.x -= tv.textContainerInset.left
            location.y -= tv.textContainerInset.top
            let lm = tv.layoutManager
            let tc = tv.textContainer
            let charIndex = lm.characterIndex(for: location, in: tc, fractionOfDistanceBetweenInsertionPoints: nil)
            let length = tv.attributedText.length
            if charIndex <= length {
                onTap?(charIndex)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        tv.alwaysBounceVertical = true
        tv.isScrollEnabled = true
        tv.showsVerticalScrollIndicator = true
        tv.indicatorStyle = .white
        // initial content
        tv.attributedText = baseAttributed(text: text, fontSize: fontSize)
        
        // Tap recognizer
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tv.addGestureRecognizer(tap)
        context.coordinator.textView = tv
        context.coordinator.onTap = onTapAtIndex
        
        context.coordinator.lastText = text
        context.coordinator.lastFontSize = fontSize
        return tv
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update tap callback
        context.coordinator.onTap = onTapAtIndex
        
        // Rebuild base attributed text only if content or size changed
        if context.coordinator.lastText != text || context.coordinator.lastFontSize != fontSize {
            uiView.attributedText = baseAttributed(text: text, fontSize: fontSize)
            context.coordinator.lastText = text
            context.coordinator.lastFontSize = fontSize
            context.coordinator.lastHighlight = nil
        }
        
        // Update highlight efficiently
        let fullLength = uiView.attributedText.length
        
        if let prev = context.coordinator.lastHighlight, NSMaxRange(prev) <= fullLength {
            uiView.textStorage.removeAttribute(.backgroundColor, range: prev)
        }
        
        if let r = highlightRange, NSMaxRange(r) <= fullLength {
            uiView.textStorage.addAttribute(.backgroundColor,
                                            value: UIColor.systemYellow.withAlphaComponent(0.35),
                                            range: r)
            uiView.layoutIfNeeded()
            uiView.scrollRangeToVisible(r)
            context.coordinator.lastHighlight = r
        } else {
            context.coordinator.lastHighlight = nil
        }
    }
    
    private func baseAttributed(text: String, fontSize: CGFloat) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: text)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        attr.addAttributes(attrs, range: NSRange(location: 0, length: (text as NSString).length))
        return attr
    }
}
