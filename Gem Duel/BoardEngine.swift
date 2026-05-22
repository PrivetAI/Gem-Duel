import Foundation

// A single board cell. Empty == nil kind during resolution.
// `id` is a stable identity that travels with a gem as it falls, so the UI can
// slide a gem (rather than crossfade it) when it moves to a new row.
struct Cell: Equatable {
    var kind: GemKind?
    var special: GemSpecial = .none
    var id = UUID()
}

// One animation step captured during turn resolution so the UI can replay
// swap → clear → fall as separate, animated beats.
struct BoardFrame {
    enum Step { case swap, clear, fall }
    let step: Step
    let grid: [[Cell]]
}

// Aggregated effect totals produced by clearing gems in a turn.
struct EffectTally {
    var swordHits = 0
    var shieldGems = 0
    var heartGems = 0
    var manaGems = 0
    var coinGems = 0
    var starGems = 0
    var totalCleared = 0
    var cascades = 0

    mutating func add(kind: GemKind, count: Int) {
        switch kind {
        case .sword: swordHits += count
        case .shield: shieldGems += count
        case .heart: heartGems += count
        case .mana: manaGems += count
        case .coin: coinGems += count
        case .star: starGems += count
        }
        totalCleared += count
    }
}

// The deterministic match-3 board engine. 8x8, 6 gem types.
final class BoardEngine {
    static let size = 8
    let typeCount = 6

    private(set) var grid: [[Cell]]   // grid[row][col]; row 0 = top
    private var rng: GemDuelSeededRNG

    init(seed: UInt64) {
        rng = GemDuelSeededRNG(seed: seed)
        grid = Array(repeating: Array(repeating: Cell(kind: .sword), count: BoardEngine.size),
                     count: BoardEngine.size)
        generateNoMatchBoard()
    }

    // MARK: - Generation (no pre-existing matches, and at least one valid move)

    private func generateNoMatchBoard() {
        repeat {
            for r in 0..<BoardEngine.size {
                for c in 0..<BoardEngine.size {
                    grid[r][c] = Cell(kind: randomNonMatchingKind(row: r, col: c))
                }
            }
        } while findAllMatches().isEmpty == false || hasAnyValidMove() == false
    }

    private func randomNonMatchingKind(row r: Int, col c: Int) -> GemKind {
        var attempts = 0
        while true {
            let k = GemKind(rawValue: rng.nextInt(typeCount)) ?? .sword
            // Avoid creating a horizontal triple with two left.
            if c >= 2, grid[r][c-1].kind == k, grid[r][c-2].kind == k { attempts += 1; if attempts < 12 { continue } }
            // Avoid creating a vertical triple with two above.
            if r >= 2, grid[r-1][c].kind == k, grid[r-2][c].kind == k { attempts += 1; if attempts < 12 { continue } }
            return k
        }
    }

    // MARK: - Match detection

    struct MatchGroup {
        var coords: Set<[Int]>     // [row, col]
        var kind: GemKind
        var maxRun: Int            // longest straight run length
        var isLShapeOrT: Bool      // intersecting runs
    }

    // Returns connected match groups of 3+.
    func findAllMatches() -> [MatchGroup] {
        var matchedH = Array(repeating: Array(repeating: false, count: BoardEngine.size), count: BoardEngine.size)
        var matchedV = Array(repeating: Array(repeating: false, count: BoardEngine.size), count: BoardEngine.size)

        // Horizontal runs
        for r in 0..<BoardEngine.size {
            var c = 0
            while c < BoardEngine.size {
                guard let k = grid[r][c].kind else { c += 1; continue }
                var run = 1
                while c + run < BoardEngine.size, grid[r][c+run].kind == k { run += 1 }
                if run >= 3 { for i in 0..<run { matchedH[r][c+i] = true } }
                c += run
            }
        }
        // Vertical runs
        for c in 0..<BoardEngine.size {
            var r = 0
            while r < BoardEngine.size {
                guard let k = grid[r][c].kind else { r += 1; continue }
                var run = 1
                while r + run < BoardEngine.size, grid[r+run][c].kind == k { run += 1 }
                if run >= 3 { for i in 0..<run { matchedV[r+i][c] = true } }
                r += run
            }
        }

        // Union matched cells into connected groups (same kind, 4-neighbour).
        var visited = Array(repeating: Array(repeating: false, count: BoardEngine.size), count: BoardEngine.size)
        var groups: [MatchGroup] = []
        for r in 0..<BoardEngine.size {
            for c in 0..<BoardEngine.size {
                if (matchedH[r][c] || matchedV[r][c]) && !visited[r][c], let k = grid[r][c].kind {
                    var stack = [[r, c]]
                    var coords = Set<[Int]>()
                    visited[r][c] = true
                    while let cur = stack.popLast() {
                        coords.insert(cur)
                        let rr = cur[0], cc = cur[1]
                        let neigh = [[rr-1, cc], [rr+1, cc], [rr, cc-1], [rr, cc+1]]
                        for n in neigh {
                            let nr = n[0], nc = n[1]
                            if nr >= 0, nr < BoardEngine.size, nc >= 0, nc < BoardEngine.size,
                               !visited[nr][nc], (matchedH[nr][nc] || matchedV[nr][nc]),
                               grid[nr][nc].kind == k {
                                visited[nr][nc] = true
                                stack.append([nr, nc])
                            }
                        }
                    }
                    // Compute max straight run within the group and whether it's L/T.
                    let (maxRun, isLT) = analyzeGroup(coords: coords, matchedH: matchedH, matchedV: matchedV)
                    groups.append(MatchGroup(coords: coords, kind: k, maxRun: maxRun, isLShapeOrT: isLT))
                }
            }
        }
        return groups
    }

    private func analyzeGroup(coords: Set<[Int]>,
                              matchedH: [[Bool]], matchedV: [[Bool]]) -> (Int, Bool) {
        var hasH = false, hasV = false
        var maxRun = 0
        // group rows/cols
        let rows = Set(coords.map { $0[0] })
        let cols = Set(coords.map { $0[1] })
        // Longest horizontal run in group
        for r in rows {
            var run = 0
            for c in 0..<BoardEngine.size {
                if coords.contains([r, c]) { run += 1; maxRun = max(maxRun, run); if run >= 3 { hasH = true } }
                else { run = 0 }
            }
        }
        for c in cols {
            var run = 0
            for r in 0..<BoardEngine.size {
                if coords.contains([r, c]) { run += 1; maxRun = max(maxRun, run); if run >= 3 { hasV = true } }
                else { run = 0 }
            }
        }
        let isLT = hasH && hasV
        return (maxRun, isLT)
    }

    // MARK: - Swap validity

    func areAdjacent(_ a: (Int, Int), _ b: (Int, Int)) -> Bool {
        let dr = abs(a.0 - b.0), dc = abs(a.1 - b.1)
        return (dr + dc) == 1
    }

    // Swap two cells in-place.
    private func swapCells(_ a: (Int, Int), _ b: (Int, Int)) {
        let tmp = grid[a.0][a.1]
        grid[a.0][a.1] = grid[b.0][b.1]
        grid[b.0][b.1] = tmp
    }

    // Returns true if swapping a and b creates a match OR if either is a special tile
    // (specials may be activated by swapping). Otherwise the swap is rejected.
    func swapWouldMatch(_ a: (Int, Int), _ b: (Int, Int)) -> Bool {
        guard areAdjacent(a, b) else { return false }
        if grid[a.0][a.1].special != .none || grid[b.0][b.1].special != .none {
            return true
        }
        swapCells(a, b)
        let matched = !findAllMatches().isEmpty
        swapCells(a, b) // revert
        return matched
    }

    func hasAnyValidMove() -> Bool {
        for r in 0..<BoardEngine.size {
            for c in 0..<BoardEngine.size {
                if c + 1 < BoardEngine.size, swapWouldMatch((r, c), (r, c+1)) { return true }
                if r + 1 < BoardEngine.size, swapWouldMatch((r, c), (r+1, c)) { return true }
            }
        }
        return false
    }

    // MARK: - Turn resolution

    // Result of resolving one swap: aggregated effects + whether anything happened.
    // Also returns the ordered animation frames (swap → clear → fall per cascade)
    // so the UI can replay the resolution as discrete animated beats. The board
    // computation and seeded-RNG consumption are identical to a non-animated
    // resolution, so the final grid and tally are deterministic and unchanged.
    func performSwap(_ a: (Int, Int), _ b: (Int, Int)) -> (frames: [BoardFrame], tally: EffectTally)? {
        guard swapWouldMatch(a, b) else { return nil }
        var frames: [BoardFrame] = []
        swapCells(a, b)
        frames.append(BoardFrame(step: .swap, grid: grid))

        var tally = EffectTally()

        // If a special was directly swapped, activate it immediately.
        var forcedClears = Set<[Int]>()
        for pos in [a, b] {
            let cell = grid[pos.0][pos.1]
            if cell.special != .none {
                forcedClears.formUnion(activationCells(forSpecialAt: (pos.0, pos.1), special: cell.special))
            }
        }
        if !forcedClears.isEmpty {
            applyClears(forcedClears, into: &tally, allowSpecialCreation: false)
            frames.append(BoardFrame(step: .clear, grid: grid))
            collapseAndRefill()
            frames.append(BoardFrame(step: .fall, grid: grid))
        }

        // Resolve cascades from matches.
        var cascadeIndex = 0
        var safety = 0
        while true {
            safety += 1
            if safety > 200 { break }   // hard cap against pathological refill chains
            let groups = findAllMatches()
            if groups.isEmpty { break }
            cascadeIndex += 1
            tally.cascades = max(tally.cascades, cascadeIndex)

            // Determine which cells clear and which become specials this cascade.
            var clears = Set<[Int]>()
            var specialsToCreate: [(pos: [Int], kind: GemKind, special: GemSpecial)] = []
            for g in groups {
                for coord in g.coords { clears.insert(coord) }
                // 4-match -> line clear; 5+/L/T -> bomb
                if g.maxRun >= 5 || g.isLShapeOrT {
                    if let pivot = pivotCoord(for: g) {
                        specialsToCreate.append((pivot, g.kind, .bomb))
                    }
                } else if g.maxRun == 4 {
                    if let pivot = pivotCoord(for: g) {
                        // Orientation based on dominant run direction.
                        let special: GemSpecial = isHorizontalDominant(g) ? .lineH : .lineV
                        specialsToCreate.append((pivot, g.kind, special))
                    }
                }
            }

            // Activate any specials that were part of the matched groups (chain).
            var chainClears = Set<[Int]>()
            for coord in clears {
                let cell = grid[coord[0]][coord[1]]
                if cell.special != .none {
                    chainClears.formUnion(activationCells(forSpecialAt: (coord[0], coord[1]), special: cell.special))
                }
            }
            clears.formUnion(chainClears)

            // Cascade bonus: deeper cascades grant a bonus sword/star scaling handled in tally via cascadeIndex.
            applyClears(clears, into: &tally, allowSpecialCreation: false)
            // Capture the "clear" beat: matched cells are now empty holes (gems fade out).
            frames.append(BoardFrame(step: .clear, grid: grid))

            // Place new specials (do not place where a clear already removed and refilled — place at pivot before collapse).
            for s in specialsToCreate {
                // Only place if the pivot was cleared this round (it is part of clears).
                grid[s.pos[0]][s.pos[1]] = Cell(kind: s.kind, special: s.special)
            }

            collapseAndRefill()
            // Capture the "fall" beat: survivors slide down, new gems drop from above.
            frames.append(BoardFrame(step: .fall, grid: grid))
        }

        return (frames, tally)
    }

    private func isHorizontalDominant(_ g: MatchGroup) -> Bool {
        let rows = Set(g.coords.map { $0[0] })
        let cols = Set(g.coords.map { $0[1] })
        return cols.count >= rows.count
    }

    // Choose a representative cell to host the new special tile.
    private func pivotCoord(for g: MatchGroup) -> [Int]? {
        // Prefer an intersection cell for L/T; otherwise the middle of the longest run.
        // Simple deterministic choice: the smallest [row,col] in the group.
        return g.coords.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }.first
    }

    // Which cells a special clears when activated.
    private func activationCells(forSpecialAt pos: (Int, Int), special: GemSpecial) -> Set<[Int]> {
        var cells = Set<[Int]>()
        switch special {
        case .none:
            break
        case .lineH:
            for c in 0..<BoardEngine.size { cells.insert([pos.0, c]) }
        case .lineV:
            for r in 0..<BoardEngine.size { cells.insert([r, pos.1]) }
        case .bomb:
            for dr in -1...1 { for dc in -1...1 {
                let nr = pos.0 + dr, nc = pos.1 + dc
                if nr >= 0, nr < BoardEngine.size, nc >= 0, nc < BoardEngine.size { cells.insert([nr, nc]) }
            } }
        }
        return cells
    }

    private func applyClears(_ clears: Set<[Int]>, into tally: inout EffectTally, allowSpecialCreation: Bool) {
        for coord in clears {
            let r = coord[0], c = coord[1]
            if let k = grid[r][c].kind {
                tally.add(kind: k, count: 1)
            }
            grid[r][c] = Cell(kind: nil)
        }
    }

    // Gravity: gems fall to fill nil cells, then refill from top with the seeded RNG.
    private func collapseAndRefill() {
        for c in 0..<BoardEngine.size {
            // Pull existing gems down.
            var write = BoardEngine.size - 1
            for r in stride(from: BoardEngine.size - 1, through: 0, by: -1) {
                if grid[r][c].kind != nil {
                    if write != r {
                        grid[write][c] = grid[r][c]
                        grid[r][c] = Cell(kind: nil)
                    }
                    write -= 1
                }
            }
            // Refill the rest from the top deterministically.
            for r in stride(from: write, through: 0, by: -1) {
                let k = GemKind(rawValue: rng.nextInt(typeCount)) ?? .sword
                grid[r][c] = Cell(kind: k)
            }
        }
    }

    // After a turn, if the board is locked (no valid move), reshuffle deterministically.
    func ensurePlayable() {
        var guardCount = 0
        while !hasAnyValidMove() && guardCount < 30 {
            reshuffle()
            guardCount += 1
        }
    }

    private func reshuffle() {
        // Collect all kinds, shuffle deterministically, re-lay avoiding immediate matches if possible.
        var kinds: [GemKind] = []
        for r in 0..<BoardEngine.size { for c in 0..<BoardEngine.size { if let k = grid[r][c].kind { kinds.append(k) } } }
        // Fisher–Yates with seeded RNG.
        var i = kinds.count - 1
        while i > 0 {
            let j = rng.nextInt(i + 1)
            kinds.swapAt(i, j)
            i -= 1
        }
        var idx = 0
        for r in 0..<BoardEngine.size {
            for c in 0..<BoardEngine.size {
                grid[r][c] = Cell(kind: idx < kinds.count ? kinds[idx] : (GemKind(rawValue: rng.nextInt(typeCount)) ?? .sword))
                idx += 1
            }
        }
        // Clear any accidental pre-matches by resolving them silently into the board state
        // (these would be auto-cleared at next resolution; acceptable). Keep specials cleared.
        for r in 0..<BoardEngine.size { for c in 0..<BoardEngine.size { grid[r][c].special = .none } }
    }
}
