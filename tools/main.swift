// ∅ 2024 super-metal-mons

import Foundation

var count = 0

func validate(data: Data) {
    let testCase = try! JSONDecoder().decode(TestCase.self, from: data)
    let game = MonsGame(fen: testCase.fenBefore)!
    let result = game.processInput(testCase.input, doNotApplyEvents: false, oneOptionEnough: false)
    
    let inputFen = testCase.input.fen
    let outputFen = testCase.output.fen
    let recreatedInput = Array<Input>(fen: inputFen)
    let recreatedOutput = Output(fen: outputFen)
    
    if recreatedInput != testCase.input || recreatedOutput != testCase.output {
        print("🛑 input / output fen")
    } else {
        print("✅ input / output fen")
    }
    
    let outputSame = result == testCase.output
    let fenSame = game.fen == testCase.fenAfter
    if outputSame && fenSame {
        count += 1
        print("✅ ok \(count)")
        // TODO: save as fen
    } else {
        if !outputSame {
            print("🛑 output", result)
            print("💾 output", testCase.output)
        }
        if !fenSame {
            print("🛑 fen", game.fen)
            print("💾 fen", testCase.fenAfter)
        }
        assert(false)
    }
}

let testDataDirectory = FileManager.default.currentDirectoryPath + "/tools/test-data"
let files = try! FileManager.default.contentsOfDirectory(atPath: testDataDirectory)

for name in files {
    if name.hasPrefix(".") { continue }
    let filePath = testDataDirectory + "/" + name
    let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
    validate(data: data)
}

print("all done")
