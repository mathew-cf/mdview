import Testing
@testable import MDView

@Suite("FuzzyMatch")
struct FuzzyMatchTests {

    // MARK: - Basic matching

    @Test func emptyQueryMatchesEverything() {
        #expect(FuzzyMatch.score(query: "", target: "anything") == 0)
    }

    @Test func emptyTargetReturnsNil() {
        #expect(FuzzyMatch.score(query: "a", target: "") == nil)
    }

    @Test func exactMatchReturnsScore() {
        let score = FuzzyMatch.score(query: "readme", target: "readme")
        #expect(score != nil)
        #expect(score! > 0)
    }

    @Test func noMatchReturnsNil() {
        #expect(FuzzyMatch.score(query: "xyz", target: "abc") == nil)
    }

    @Test func queryLongerThanTargetReturnsNil() {
        #expect(FuzzyMatch.score(query: "abcdef", target: "abc") == nil)
    }

    // MARK: - Case insensitivity

    @Test func caseInsensitive() {
        let lower = FuzzyMatch.score(query: "readme", target: "README.md")
        let upper = FuzzyMatch.score(query: "README", target: "README.md")
        #expect(lower != nil)
        #expect(upper != nil)
        #expect(lower == upper)
    }

    @Test func mixedCaseQuery() {
        #expect(FuzzyMatch.score(query: "ReAdMe", target: "readme.md") != nil)
    }

    // MARK: - Streak bonus

    @Test func consecutiveMatchesScoreHigher() {
        let consecutive = FuzzyMatch.score(query: "abc", target: "abcxyz")!
        let scattered = FuzzyMatch.score(query: "abc", target: "axbxcx")!
        #expect(consecutive > scattered)
    }

    // MARK: - Boundary bonus

    @Test func boundaryCharacterBonus() {
        let atBoundary = FuzzyMatch.score(query: "m", target: "foo-match")!
        let notBoundary = FuzzyMatch.score(query: "m", target: "foomatxx")!
        #expect(atBoundary > notBoundary)
    }

    @Test func startOfStringBonus() {
        let atStart = FuzzyMatch.score(query: "a", target: "abcdef")!
        let inMiddle = FuzzyMatch.score(query: "c", target: "abcdef")!
        #expect(atStart > inMiddle)
    }

    // MARK: - Length penalty

    @Test func shorterTargetScoresHigher() {
        let short = FuzzyMatch.score(query: "a", target: "a")!
        let long = FuzzyMatch.score(query: "a", target: "a" + String(repeating: "x", count: 100))!
        #expect(short > long)
    }

    // MARK: - Ordering / ranking

    @Test func exactFilenameRanksAboveDeepPath() {
        let exact = FuzzyMatch.score(query: "readme", target: "readme.md")!
        let deep = FuzzyMatch.score(query: "readme", target: "some/very/deep/path/readme.md")!
        #expect(exact > deep)
    }

    @Test func prefixMatchRanksHigher() {
        let prefix = FuzzyMatch.score(query: "app", target: "AppState.swift")!
        let middle = FuzzyMatch.score(query: "app", target: "zzappzz.swift")!
        #expect(prefix > middle)
    }

    // MARK: - Partial matches

    @Test func subsequenceMatch() {
        #expect(FuzzyMatch.score(query: "fzy", target: "fuzzy") != nil)
    }

    @Test func nonSubsequenceReturnsNil() {
        #expect(FuzzyMatch.score(query: "ba", target: "abc") == nil)
    }

    // MARK: - Real-world scenarios

    @Test func typicalQuickOpenQuery() {
        let appState = FuzzyMatch.score(query: "appst", target: "Sources/MDView/AppState.swift")!
        if let appSwiftScore = FuzzyMatch.score(query: "appst", target: "Sources/MDView/App.swift") {
            #expect(appState > appSwiftScore)
        }
    }

    // MARK: - Edge cases

    @Test func singleCharacterMatch() {
        let score = FuzzyMatch.score(query: "a", target: "a")
        #expect(score != nil)
        #expect(score! > 0)
    }

    @Test func bothEmpty() {
        #expect(FuzzyMatch.score(query: "", target: "") == 0)
    }

    @Test func specialCharactersInTarget() {
        #expect(FuzzyMatch.score(query: "test", target: "my_test-file.swift") != nil)
    }

    @Test func slashBoundary() {
        #expect(FuzzyMatch.score(query: "r", target: "path/readme") != nil)
    }

    @Test func dotBoundary() {
        #expect(FuzzyMatch.score(query: "m", target: "readme.md") != nil)
    }

    @Test func underscoreBoundary() {
        #expect(FuzzyMatch.score(query: "b", target: "foo_bar") != nil)
    }
}
