// Writes the source lists in Package.swift from the pinned submodules: the .c files in ngtcp2's and
// nghttp3's lib/. SwiftPM reads a dependency's manifest from git without its submodules, so the
// manifest itself cannot read them. Run as `mise run sources`.
import Foundation

/// The .c files directly in Sources/<target>/<directory>, as paths relative to the target.
func cFiles(_ target: String, _ directory: String) throws -> [String] {
    try FileManager.default.contentsOfDirectory(atPath: "Sources/\(target)/\(directory)")
        .filter { $0.hasSuffix(".c") }
        .sorted()
        .map { "\(directory)/\($0)" }
}

func list(_ name: String, _ files: [String]) -> String {
    "let \(name): [String] = [\n" + files.map { "    \"\($0)\",\n" }.joined() + "]\n"
}

let lists = [
    list("ngtcp2Sources", try cFiles("ngtcp2", "ngtcp2/lib")
        + ["ngtcp2/crypto/shared.c", "ngtcp2/crypto/boringssl/boringssl.c"]),
    list("nghttp3Sources", try cFiles("nghttp3", "nghttp3/lib") + ["nghttp3/lib/sfparse/sfparse.c"]),
].joined(separator: "\n")

let begin = "// BEGIN sources, written by `mise run sources`\n"
let end = "// END sources\n"
var manifest = try String(contentsOfFile: "Package.swift", encoding: .utf8)
guard let start = manifest.range(of: begin), let stop = manifest.range(of: end) else {
    fatalError("Package.swift lacks the lines \(begin)and \(end)")
}
manifest.replaceSubrange(start.upperBound..<stop.lowerBound, with: lists)
try manifest.write(toFile: "Package.swift", atomically: true, encoding: .utf8)
