//
//  ContentView.swift
//  WordGarrden
//
//  Created by Mohammad Eid on 29/10/2024.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    private let dictionary = ["SWIFT", "DOG", "CAT"]
    private let maxIncorrectGuesses = 8
    
    // Game scoped states
    @State private var currentWordIndex = 0
    @State private var wordsGuessed = 0
    private var wordsMissed: Int { currentWordIndex - wordsGuessed + (wordGuessedCorrectly ? 1 : 0) }
    private var currentWord: String { dictionary[currentWordIndex] }
    
    // Round scoped states
    @State private var guessesCount = 0
    @State private var incorrectGuessesCount = 0
    @State private var lettersGuessed = Set<Character>()
    private var remainingGuesses: Int { maxIncorrectGuesses - incorrectGuessesCount }
    private var gameStatusMessage: String {
        if wordGuessedCorrectly {
            "You've Guessed It! It Took You \(guessesCount) Guesses to Guess the Word."
        } else if remainingGuesses == 0 {
            "So Sorry, You're All Out of Guesses."
        } else if guessesCount == 0 {
            "How Many Guesses to Uncover the Hdden Word?"
        } else {
            "You've Made \(guessesCount) Guess\(guessesCount == 1 ? "" : "es")"
        }
    }
    private var revealedWord: String {
        currentWord.map {
            lettersGuessed.contains($0) ? "\($0)" : "_"
        }.joined(separator: " ")
    }
    private var wordGuessedCorrectly: Bool { !revealedWord.contains("_") }
    
    
    @State private var letterInTextField = ""
    
    @State private var flowerWilting = false
    private var flowerImage: String {
        flowerWilting ? "wilt\(remainingGuesses)" : "flower\(remainingGuesses)"
    }
    
    private var gameOver: Bool { currentWordIndex == dictionary.count - 1 && roundOver }
    private var roundOver: Bool { remainingGuesses == 0 || wordGuessedCorrectly }
    
    @State private var audioPlayer: AVAudioPlayer!
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Words Guessed: \(wordsGuessed)")
                    Text("Words Missed: \(wordsMissed)")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Words remaining: \(dictionary.count - wordsGuessed - wordsMissed)")
                    Text("Words in Game: \(dictionary.count)")
                }
            }
            
            Spacer()
            
            Text(gameStatusMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(height: 80)
                .minimumScaleFactor(0.5)
                .padding()
            
            Spacer()
            
            Text(revealedWord)
                .font(.title)
            
            if gameOver {
                Button("Play again?") {
                    currentWordIndex = 0
                    wordsGuessed = 0
                    resetRound()
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            } else if roundOver {
                Button("Another Word?") {
                    currentWordIndex += 1
                    resetRound()
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            } else {
                HStack {
                    TextField("", text: $letterInTextField)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 30)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 2)
                        }
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .onSubmit {
                            guard !letterInTextField.isEmpty else { return }
                            guessALetter()
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: letterInTextField) {
                            letterInTextField = letterInTextField.trimmingCharacters(in: .letters.inverted)
                            guard let lastChar = letterInTextField.last else { return }
                            letterInTextField = String(lastChar).uppercased()
                        }
                    
                    Button("Guess a letter") {
                        guessALetter()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(letterInTextField.isEmpty)
                }
            }
            
            Spacer(minLength: 40)
            
            Image(flowerImage)
                .resizable()
                .scaledToFit()
                .animation(.easeIn(duration: 0.75), value: flowerImage)
        }
        .ignoresSafeArea(edges: .bottom)
        .padding(.horizontal)
    }
    
    func guessALetter() {
        let enteredLetter = letterInTextField.first!
        let correctLetter = currentWord.contains(enteredLetter);
        
        lettersGuessed.insert(enteredLetter)
        letterInTextField = ""
        guessesCount += 1
        
        if !correctLetter {
            incorrectGuessesCount += 1
            flowerWilting = true
            Task {
                try? await Task.sleep(for: Duration.milliseconds(750))
                flowerWilting = false
            }
        }
        
        if wordGuessedCorrectly {
            wordsGuessed += 1
        }
        
        if correctLetter {
            if (wordGuessedCorrectly) {
                playSound("word-guessed")
            } else {
                playSound("correct")
            }
        } else {
            if remainingGuesses == 0 {
                playSound("word-not-guessed")
            } else {
                playSound("incorrect")
            }
        }
    }
    
    func resetRound() {
        guessesCount = 0
        incorrectGuessesCount = 0
        lettersGuessed.removeAll()
    }
    
    func playSound(_ soundName: String) {
        guard let soundFile = NSDataAsset(name: soundName) else {
            print("😡 Could not read file named \(soundName)")
            return
        }
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        } catch {
            print("😡 ERROR: \(error.localizedDescription) creating audio player.")
        }
    }
}

#Preview {
    ContentView()
}
