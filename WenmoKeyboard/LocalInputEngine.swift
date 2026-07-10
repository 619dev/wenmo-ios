import Foundation

struct Candidate: Equatable {
    let simplified: String
    let traditional: String
}

final class LocalInputEngine {
    enum Script { case simplified, traditional }

    private(set) var composition = ""
    var script: Script = .simplified
    private var index: [String: [Candidate]] = [:]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "cedict_pinyin", withExtension: "tsv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        for line in text.split(separator: "\n") where !line.hasPrefix("#") {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count == 3 else { continue }
            let key = String(fields[0])
            guard index[key, default: []].count < 48 else { continue }
            index[key, default: []].append(Candidate(simplified: String(fields[1]), traditional: String(fields[2])))
        }
    }

    func type(_ letter: String) {
        guard letter.count == 1, letter.first?.isASCII == true, letter.first?.isLowercase == true else { return }
        composition.append(letter)
    }

    func backspace() { if !composition.isEmpty { composition.removeLast() } }
    func clear() { composition = "" }

    var candidates: [String] {
        let values = index[composition] ?? []
        return values.map { script == .simplified ? $0.simplified : $0.traditional }
    }
}
