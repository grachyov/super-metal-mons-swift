// Copyright © 2023 super metal mons. All rights reserved.

import AVFoundation

struct Audio {
    
    private static let queue = DispatchQueue.global(qos: .userInitiated)
    private static var players = [Sound: AVAudioPlayer]()
    
    static func prepare() {
        queue.async {
            for sound in Sound.allCases {
                guard let soundFileURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                      let player = try? AVAudioPlayer(contentsOf: soundFileURL) else { continue }
                players[sound] = player
            }
            
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
        }
    }
    
    static func play(_ sound: Sound) {
        play(sounds: [sound])
    }
    
    static func play(sounds: [Sound]) {
        guard !Defaults.isSoundDisabled else { return }
        
        queue.async {
            try? AVAudioSession.sharedInstance().setActive(true)
            for sound in sounds {
                let player = players[sound]
                player?.play()
            }
        }
    }

}
