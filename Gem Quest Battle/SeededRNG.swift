import Foundation

// Deterministic seeded random number generator using SplitMix64 integer mixing.
// NEVER uses String.hashValue or Hasher() — pure integer math for reproducibility.
struct GemQuestSeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state degenerating; mix the seed once on init.
        self.state = seed &+ 0x9E3779B97F4A7C15
    }

    // Core SplitMix64 step.
    mutating func nextU64() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return z
    }

    // Uniform integer in 0..<bound (bound > 0).
    mutating func nextInt(_ bound: Int) -> Int {
        guard bound > 0 else { return 0 }
        return Int(nextU64() % UInt64(bound))
    }

    // Inclusive range helper.
    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = range.upperBound - range.lowerBound + 1
        return range.lowerBound + nextInt(span)
    }

    // Double in 0..<1.
    mutating func nextDouble() -> Double {
        // 53-bit mantissa precision.
        let v = nextU64() >> 11
        return Double(v) * (1.0 / 9007199254740992.0)
    }

    // Returns true with probability p (0...1).
    mutating func chance(_ p: Double) -> Bool {
        return nextDouble() < p
    }
}

// Helper to build a stable seed from integer inputs without Hasher.
func gemQuestMixSeed(_ a: Int, _ b: Int, _ c: Int = 0) -> UInt64 {
    var s: UInt64 = 0xD1B54A32D192ED03
    s = (s ^ UInt64(bitPattern: Int64(a))) &* 0x9E3779B97F4A7C15
    s = (s ^ UInt64(bitPattern: Int64(b))) &* 0xC2B2AE3D27D4EB4F
    s = (s ^ UInt64(bitPattern: Int64(c))) &* 0x165667B19E3779F9
    s = s ^ (s >> 33)
    return s
}
