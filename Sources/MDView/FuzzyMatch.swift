enum FuzzyMatch {
    static func score(query: String, target: String) -> Int? {
        let q = Array(query.lowercased())
        let t = Array(target.lowercased())

        guard !q.isEmpty else { return 0 }
        guard q.count <= t.count else { return nil }

        let filenameStart = (t.lastIndex(of: "/") ?? -1) + 1

        var qi = 0
        var score = 0
        var streak = 0
        var prev = -2

        for i in t.indices {
            guard qi < q.count else { break }
            guard t[i] == q[qi] else { continue }

            score += 1

            if i == prev + 1 {
                streak += 1
                score += streak * 3
            } else {
                streak = 0
            }

            if i == 0 || "/\\.-_ ".contains(t[i - 1]) {
                score += 5
            }

            if i >= filenameStart {
                score += 2
            }

            prev = i
            qi += 1
        }

        guard qi == q.count else { return nil }
        score += max(0, 100 - t.count) / 5
        return score
    }
}
