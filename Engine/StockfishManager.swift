import Foundation

final class StockfishManager {
    struct PVLine {
        let move: String
        let score: Int
        let depth: Int
        let line: [String]
    }

    struct HumanProfile {
        var skill: Double
        var blunderRate: Double
        var aggression: Double
        var positionalBias: Double
        var timeVariance: Double
        var tacticalSharpness: Double
        var tiltFactor: Double
        var confidence: Double
        var timePressurePerformance: Double

        static let beginner = HumanProfile(skill: 0.2, blunderRate: 0.36, aggression: 0.42, positionalBias: 0.2, timeVariance: 0.85, tacticalSharpness: 0.2, tiltFactor: 0.65, confidence: 0.35, timePressurePerformance: 0.2)
        static let casual = HumanProfile(skill: 0.4, blunderRate: 0.23, aggression: 0.55, positionalBias: 0.35, timeVariance: 0.6, tacticalSharpness: 0.38, tiltFactor: 0.45, confidence: 0.5, timePressurePerformance: 0.45)
        static let club = HumanProfile(skill: 0.6, blunderRate: 0.14, aggression: 0.62, positionalBias: 0.55, timeVariance: 0.5, tacticalSharpness: 0.58, tiltFactor: 0.28, confidence: 0.64, timePressurePerformance: 0.62)
        static let advanced = HumanProfile(skill: 0.8, blunderRate: 0.07, aggression: 0.64, positionalBias: 0.72, timeVariance: 0.35, tacticalSharpness: 0.78, tiltFactor: 0.15, confidence: 0.78, timePressurePerformance: 0.8)
        static let master = HumanProfile(skill: 0.95, blunderRate: 0.02, aggression: 0.7, positionalBias: 0.86, timeVariance: 0.2, tacticalSharpness: 0.94, tiltFactor: 0.05, confidence: 0.92, timePressurePerformance: 0.92)
    }

    enum OpeningStyle {
        case aggressive
        case defensive
        case gambit
        case positional
        case random
    }

    struct ChessBot {
        let id: String
        let name: String
        let avatar: String
        let description: String
        let elo: Int
        let personality: HumanProfile
        let openingStyle: OpeningStyle
        let endgameSkill: Double
    }

    struct Evaluation {
        let centipawns: Int
        let isMate: Bool
        let mateIn: Int?
        let depth: Int
        let bestLine: [String]
    }

    struct GameSummary {
        let accuracy: Double
        let blunders: Int
        let mistakes: Int
        let brilliants: Int
        let averageCentipawnLoss: Double
    }

    enum MoveClassification {
        case brilliant
        case great
        case best
        case excellent
        case good
        case inaccuracy
        case mistake
        case blunder
    }

    struct GameReviewItem {
        let fen: String
        let move: String
        let bestMove: String
        let evalBefore: Int
        let evalAfter: Int
        let classification: MoveClassification
    }

    struct Puzzle {
        let fen: String
        let bestMove: String
        let theme: String
    }

    private struct BookMove: Codable {
        let move: String
        let weight: Double
    }

    private struct SearchState {
        var token: Int
        var fen: String
    }

    private struct CachedSearch {
        let fen: String
        let bestMove: String
        let eval: Int
        let depth: Int
        let lines: [PVLine]
        let createdAt: Date
    }

    private final class LRUCache {
        private var storage: [String: CachedSearch] = [:]
        private var order: [String] = []
        private let capacity: Int

        init(capacity: Int) {
            self.capacity = max(capacity, 50)
        }

        func value(for key: String) -> CachedSearch? {
            guard let value = storage[key] else { return nil }
            touch(key)
            return value
        }

        func set(_ value: CachedSearch, for key: String) {
            storage[key] = value
            touch(key)
            trimIfNeeded()
        }

        private func touch(_ key: String) {
            order.removeAll { $0 == key }
            order.append(key)
        }

        private func trimIfNeeded() {
            while order.count > capacity {
                let oldest = order.removeFirst()
                storage.removeValue(forKey: oldest)
            }
        }
    }

    private var elo: Int = 1200
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var pendingCompletion: ((String?) -> Void)?
    private var isEngineReady = false
    private var hasReceivedUciOk = false
    private var isThinking = false
    private var outputBuffer = ""
    private var hasRestartedAfterCrash = false
    private var multiPV: Int = 5
    private var pvLines: [PVLine] = []
    private var currentTopMoves: [(move: String, score: Int)] = []
    private var difficulty: Double = 0.7
    private var blunderRate: Double = 0.1
    private var currentEvaluation: Int = 0
    private var currentMateIn: Int?
    private var latestBestMove: String?
    private var latestDepth: Int = 0
    private var openingBook: [String: [BookMove]] = [:]
    private var openingStyle: OpeningStyle = .random
    private var profile: HumanProfile = .advanced
    private var selectedBot: ChessBot?
    private var searchStartTime: Date?
    private var stopWorkItem: DispatchWorkItem?
    private var ponderStopWorkItem: DispatchWorkItem?
    private var searchToken: Int = 0
    private var activeSearch: SearchState?
    private var isPondering = false
    private var evalHeuristicCache: [String: Int] = [:]
    private var searchCache = LRUCache(capacity: 512)
    private var ponderPositionFen: String?
    private var ponderExpectedOpponentMove: String?
    private var ponderCachedReplyMove: String?
    private var lastAnalyzedSummary: GameSummary?
    private let engineQueue = DispatchQueue(label: "com.endgame.stockfish.engine", qos: .userInitiated)
    private let stateQueue = DispatchQueue(label: "com.endgame.stockfish.state", qos: .userInitiated)
    private let stateQueueKey = DispatchSpecificKey<Void>()

    static let botLadder: [ChessBot] = [
        ChessBot(id: "grandma_lina", name: "Grandma Lina", avatar: "grandma_lina", description: "Calm and forgiving beginner bot.", elo: 400, personality: .beginner, openingStyle: .defensive, endgameSkill: 0.2),
        ChessBot(id: "lazy_panda", name: "Lazy Panda", avatar: "lazy_panda", description: "Slow but occasionally tactical.", elo: 600, personality: .beginner, openingStyle: .random, endgameSkill: 0.25),
        ChessBot(id: "club_raj", name: "Club Player Raj", avatar: "club_raj", description: "Practical club-level chess.", elo: 1200, personality: .casual, openingStyle: .positional, endgameSkill: 0.45),
        ChessBot(id: "tactical_tom", name: "Tactical Tom", avatar: "tactical_tom", description: "Always hunting combinations.", elo: 1400, personality: .club, openingStyle: .aggressive, endgameSkill: 0.5),
        ChessBot(id: "endgame_master", name: "Endgame Master", avatar: "endgame_master", description: "Precision rises in endgames.", elo: 1800, personality: .advanced, openingStyle: .positional, endgameSkill: 0.85),
        ChessBot(id: "sharp_attacker", name: "Sharp Attacker", avatar: "sharp_attacker", description: "Aggressive and tactical pressure.", elo: 2000, personality: .advanced, openingStyle: .gambit, endgameSkill: 0.72),
        ChessBot(id: "engine_lite", name: "Engine Lite", avatar: "engine_lite", description: "Strong but still humanized.", elo: 2200, personality: .master, openingStyle: .aggressive, endgameSkill: 0.9),
        ChessBot(id: "grandmaster_ai", name: "Grandmaster AI", avatar: "grandmaster_ai", description: "Near-max strength personality.", elo: 2500, personality: .master, openingStyle: .random, endgameSkill: 0.98),
        ChessBot(id: "kid_beginner", name: "Kid Beginner", avatar: "kid_beginner", description: "Learns while playing and misses tactics.", elo: 300, personality: .beginner, openingStyle: .random, endgameSkill: 0.15),
        ChessBot(id: "blunder_master", name: "Blunder Master", avatar: "blunder_master", description: "Chaotic tactics with frequent hangs.", elo: 700, personality: HumanProfile(skill: 0.33, blunderRate: 0.45, aggression: 0.68, positionalBias: 0.15, timeVariance: 0.7, tacticalSharpness: 0.32, tiltFactor: 0.8, confidence: 0.4, timePressurePerformance: 0.35), openingStyle: .gambit, endgameSkill: 0.2),
        ChessBot(id: "speed_demon", name: "Speed Demon", avatar: "speed_demon", description: "Fast decisions, volatile quality.", elo: 1100, personality: HumanProfile(skill: 0.52, blunderRate: 0.2, aggression: 0.62, positionalBias: 0.3, timeVariance: 0.95, tacticalSharpness: 0.5, tiltFactor: 0.35, confidence: 0.7, timePressurePerformance: 0.8), openingStyle: .aggressive, endgameSkill: 0.35),
        ChessBot(id: "positional_queen", name: "Positional Queen", avatar: "positional_queen", description: "Slow and strategic with steady play.", elo: 1700, personality: HumanProfile(skill: 0.76, blunderRate: 0.08, aggression: 0.35, positionalBias: 0.9, timeVariance: 0.28, tacticalSharpness: 0.65, tiltFactor: 0.12, confidence: 0.72, timePressurePerformance: 0.66), openingStyle: .defensive, endgameSkill: 0.74),
        ChessBot(id: "gambit_king", name: "Gambit King", avatar: "gambit_king", description: "Sacrifices early to attack.", elo: 1650, personality: HumanProfile(skill: 0.74, blunderRate: 0.12, aggression: 0.93, positionalBias: 0.35, timeVariance: 0.42, tacticalSharpness: 0.83, tiltFactor: 0.2, confidence: 0.82, timePressurePerformance: 0.7), openingStyle: .gambit, endgameSkill: 0.45),
        ChessBot(id: "endgame_beast", name: "Endgame Beast", avatar: "endgame_beast", description: "Quiet opening, deadly endings.", elo: 1900, personality: HumanProfile(skill: 0.8, blunderRate: 0.09, aggression: 0.45, positionalBias: 0.8, timeVariance: 0.32, tacticalSharpness: 0.72, tiltFactor: 0.1, confidence: 0.74, timePressurePerformance: 0.77), openingStyle: .positional, endgameSkill: 0.98)
    ]

    init() {
        stateQueue.setSpecific(key: stateQueueKey, value: ())
        loadOpeningBook()
        configureEngine()
    }

    deinit {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminate()
        stopWorkItem?.cancel()
        ponderStopWorkItem?.cancel()
    }

    func setElo(_ value: Int) {
        let bounded = min(max(value, 400), 2500)
        mutateState { [weak self] in
            guard let self else { return }
            elo = bounded
            guard isEngineReady else { return }
            send(command: "setoption name UCI_LimitStrength value true")
            send(command: "setoption name UCI_Elo value \(bounded)")
        }
    }

    func bestMove(for fen: String, completion: @escaping (String?) -> Void) {
        mutateState { [weak self] in
            guard let self else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            guard process != nil, isEngineReady else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            guard !isThinking else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            if let cached = searchCache.value(for: fen) {
                latestBestMove = cached.bestMove
                latestDepth = cached.depth
                currentEvaluation = cached.eval
                pvLines = cached.lines
                currentTopMoves = cached.lines.map { ($0.move, $0.score) }
                DispatchQueue.main.async {
                    completion(cached.bestMove)
                }
                maybeStartAutoPonder(from: fen, selectedMove: cached.bestMove)
                return
            }

            if let ponderFen = ponderPositionFen,
               ponderFen == fen,
               let move = ponderCachedReplyMove {
                latestBestMove = move
                DispatchQueue.main.async {
                    completion(move)
                }
                return
            }

            stopSearchInternal()
            isThinking = true
            pendingCompletion = completion
            resetSearchState(fen: fen)

            if let selected = bookMove(for: fen) {
                isThinking = false
                pendingCompletion = nil
                searchStartTime = nil
                latestBestMove = selected
                DispatchQueue.main.async {
                    completion(selected)
                }
                return
            }

            send(command: "ucinewgame")
            send(command: "position fen \(fen)")
            send(command: "go infinite")
            scheduleStopSearch(for: fen)
        }
    }

    func stopSearch() {
        mutateState { [weak self] in
            self?.stopSearchInternal()
        }
    }

    func getBestMoveSoFar() -> String? {
        stateRead {
            latestBestMove ?? pvLines.first?.move
        }
    }

    func setBot(_ bot: ChessBot) {
        mutateState { [weak self] in
            guard let self else { return }
            selectedBot = bot
            openingStyle = bot.openingStyle
            profile = bot.personality
            difficulty = bot.personality.skill
            blunderRate = bot.personality.blunderRate
            setElo(bot.elo)
        }
    }

    func getEvaluation() -> Int {
        stateRead { currentEvaluation }
    }

    func getEvaluationBreakdown() -> Evaluation {
        stateRead {
            Evaluation(
                centipawns: currentEvaluation,
                isMate: currentMateIn != nil,
                mateIn: currentMateIn,
                depth: latestDepth,
                bestLine: pvLines.first?.line ?? []
            )
        }
    }

    func getTopLines() -> [PVLine] {
        stateRead { pvLines }
    }

    func analyzeGame(moves: [String]) -> [GameReviewItem] {
        var board = ChessBoard()
        board.loadStandardPosition()
        var turn: PieceColor = .white
        var review: [GameReviewItem] = []

        for move in moves {
            let fenBefore = board.generateFEN(activeColor: turn)
            let evalBefore = quickEvaluate(board: board, for: turn)
            let bestMove = bestMoveByStaticEval(on: board, for: turn) ?? move

            guard let parsed = ChessBoard.parseMove(move),
                  board.move(from: parsed.from, to: parsed.to, color: turn) != nil else {
                continue
            }

            let evalAfter = quickEvaluate(board: board, for: turn)
            let classification = classifyMove(
                played: move,
                bestMove: bestMove,
                evalBefore: evalBefore,
                evalAfter: evalAfter,
                boardBefore: fenBefore
            )

            review.append(GameReviewItem(
                fen: fenBefore,
                move: move,
                bestMove: bestMove,
                evalBefore: evalBefore,
                evalAfter: evalAfter,
                classification: classification
            ))
            turn = turn.opposite
        }

        let summary = summarizeReview(review)
        mutateState { [weak self] in
            self?.lastAnalyzedSummary = summary
        }
        return review
    }

    func getLastGameSummary() -> GameSummary? {
        stateRead { lastAnalyzedSummary }
    }

    func generatePuzzle(from fen: String) -> Puzzle? {
        let top = stateRead { pvLines.first }
        guard let top, !top.move.isEmpty else { return nil }
        let theme: String
        if abs(top.score) > 90_000 || currentMateIn != nil {
            theme = "mate"
        } else if top.score > 250 {
            theme = "tactic"
        } else if top.line.count >= 3 {
            theme = ["fork", "pin", "skewer", "tactic"].randomElement() ?? "tactic"
        } else {
            theme = "tactic"
        }
        return Puzzle(fen: fen, bestMove: top.move, theme: theme)
    }

    func startPonder(fen: String) {
        mutateState { [weak self] in
            guard let self, process != nil, isEngineReady else { return }
            if isThinking { return }
            isPondering = true
            ponderPositionFen = fen
            ponderCachedReplyMove = nil
            send(command: "position fen \(fen)")
            send(command: "go infinite")

            ponderStopWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.send(command: "stop")
            }
            ponderStopWorkItem = item
            engineQueue.asyncAfter(deadline: .now() + .milliseconds(450), execute: item)
        }
    }

    func stopPonder() {
        mutateState { [weak self] in
            guard let self else { return }
            isPondering = false
            ponderPositionFen = nil
            ponderExpectedOpponentMove = nil
            ponderCachedReplyMove = nil
            ponderStopWorkItem?.cancel()
            ponderStopWorkItem = nil
            send(command: "stop")
        }
    }

    func isEndgame(board: ChessBoard) -> Bool {
        var heavyPieces = 0
        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = board.piece(at: Position(row: row, col: col)) else { continue }
                if piece.type == .queen || piece.type == .rook {
                    heavyPieces += 1
                }
            }
        }
        return heavyPieces <= 2
    }

    private func configureEngine() {
        engineQueue.async { [weak self] in
            guard let self else { return }
            guard let enginePath = Bundle.main.path(forResource: "stockfish", ofType: nil) else {
                print("Stockfish binary missing")
                self.mutateState { self.resetStateForEngineDown() }
                return
            }

            let process = Process()
            let inputPipe = Pipe()
            let outputPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: enginePath)
            process.standardInput = inputPipe
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                guard let self else { return }
                let data = handle.availableData
                if data.isEmpty {
                    self.handleEngineEOF()
                    return
                }
                guard let output = String(data: data, encoding: .utf8) else { return }
                self.handleEngineOutput(output)
            }

            do {
                try process.run()
                self.process = process
                self.inputPipe = inputPipe
                self.outputPipe = outputPipe

                self.mutateState {
                    self.isEngineReady = false
                    self.hasReceivedUciOk = false
                    self.outputBuffer = ""
                    self.hasRestartedAfterCrash = false
                }

                self.send(command: "uci")
            } catch {
                print("Failed to start Stockfish engine: \(error.localizedDescription)")
                self.cleanupEngineResources()
                self.mutateState { self.resetStateForEngineDown() }
            }
        }
    }

    private func send(command: String) {
        engineQueue.async { [weak self] in
            guard let self, let inputPipe = self.inputPipe else { return }
            guard let data = "\(command)\n".data(using: .utf8) else { return }
            inputPipe.fileHandleForWriting.write(data)
        }
    }

    private func handleEngineOutput(_ output: String) {
        mutateState { [weak self] in
            guard let self else { return }
            outputBuffer += output

            let segments = outputBuffer.split(separator: "\n", omittingEmptySubsequences: false)
            if outputBuffer.hasSuffix("\n") {
                outputBuffer = ""
            } else {
                outputBuffer = String(segments.last ?? "")
            }

            let completeLineCount = outputBuffer.isEmpty ? segments.count : max(segments.count - 1, 0)
            guard completeLineCount > 0 else { return }

            for idx in 0..<completeLineCount {
                let line = String(segments[idx]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else { continue }
                processEngineLine(line)
            }
        }
    }

    private func processEngineLine(_ line: String) {
        if line == "uciok" {
            hasReceivedUciOk = true
            send(command: "isready")
            return
        }

        if line == "readyok" {
            guard hasReceivedUciOk else { return }
            isEngineReady = true
            send(command: "setoption name UCI_LimitStrength value true")
            send(command: "setoption name UCI_Elo value \(elo)")
            send(command: "setoption name MultiPV value \(multiPV)")
            return
        }

        if line.hasPrefix("info ") {
            parseInfoLine(line)
            return
        }

        guard line.hasPrefix("bestmove") else { return }
        stopWorkItem?.cancel()
        stopWorkItem = nil

        let engineBestMove = parseBestMove(from: line)
        let selectedMove = chooseHumanLikeMove(defaultMove: engineBestMove)

        latestBestMove = selectedMove ?? engineBestMove
        isThinking = false
        searchStartTime = nil
        let completion = pendingCompletion
        pendingCompletion = nil
        guard let completion else { return }
        if let fen = activeSearch?.fen, let finalMove = selectedMove {
            let cached = CachedSearch(
                fen: fen,
                bestMove: finalMove,
                eval: currentEvaluation,
                depth: latestDepth,
                lines: pvLines,
                createdAt: Date()
            )
            searchCache.set(cached, for: fen)
            maybeStartAutoPonder(from: fen, selectedMove: finalMove)
        }
        DispatchQueue.main.async {
            completion(selectedMove)
        }
    }

    private func handleEngineEOF() {
        cleanupEngineResources()

        mutateState { [weak self] in
            guard let self else { return }
            let completion = pendingCompletion
            resetStateForEngineDown()
            DispatchQueue.main.async {
                completion?(nil)
            }

            if !hasRestartedAfterCrash {
                hasRestartedAfterCrash = true
                configureEngine()
            } else {
                print("Stockfish engine terminated and restart already attempted")
            }
        }
    }

    private func cleanupEngineResources() {
        engineQueue.async { [weak self] in
            guard let self else { return }
            outputPipe?.fileHandleForReading.readabilityHandler = nil
            process?.terminate()
            process = nil
            inputPipe = nil
            outputPipe = nil
        }
    }

    private func resetStateForEngineDown() {
        isEngineReady = false
        hasReceivedUciOk = false
        isThinking = false
        outputBuffer = ""
        pendingCompletion = nil
        currentTopMoves = []
        pvLines = []
        currentEvaluation = 0
        currentMateIn = nil
        latestBestMove = nil
        latestDepth = 0
        searchStartTime = nil
        stopWorkItem?.cancel()
        stopWorkItem = nil
        ponderStopWorkItem?.cancel()
        ponderStopWorkItem = nil
        isPondering = false
        activeSearch = nil
    }

    private func resetSearchState(fen: String) {
        searchToken += 1
        activeSearch = SearchState(token: searchToken, fen: fen)
        currentTopMoves = []
        pvLines = []
        currentEvaluation = 0
        currentMateIn = nil
        latestDepth = 0
        latestBestMove = nil
        searchStartTime = Date()
    }

    private func scheduleStopSearch() {
        let clampedDifficulty = max(0.0, min(difficulty, 1.0))
        let variance = Int(Double.random(in: -1...1) * profile.timeVariance * 250.0)
        let thinkTime = max(120, 200 + Int(clampedDifficulty * 1000) + variance)
        stopWorkItem?.cancel()

        let item = DispatchWorkItem { [weak self] in
            self?.send(command: "stop")
        }
        stopWorkItem = item
        engineQueue.asyncAfter(deadline: .now() + .milliseconds(thinkTime), execute: item)
    }

    private func parseBestMove(from line: String) -> String? {
        let parts = line.split(separator: " ")
        guard parts.count > 1 else { return nil }
        let move = String(parts[1])
        return move == "(none)" ? nil : move
    }

    private func parseInfoLine(_ line: String) {
        let tokens = line.split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return }

        var multipv = 1
        var score: Int?
        var pvMove: String?
        var pvLineMoves: [String] = []
        var depth: Int = latestDepth

        var index = 0
        while index < tokens.count {
            let token = tokens[index]
            if token == "depth", index + 1 < tokens.count {
                depth = Int(tokens[index + 1]) ?? depth
                index += 2
                continue
            }
            if token == "multipv", index + 1 < tokens.count {
                multipv = Int(tokens[index + 1]) ?? 1
                index += 2
                continue
            }

            if token == "score", index + 2 < tokens.count {
                let type = tokens[index + 1]
                let raw = Int(tokens[index + 2]) ?? 0
                if type == "cp" {
                    score = raw
                    if multipv == 1 {
                        currentEvaluation = max(min(raw, 1000), -1000)
                        currentMateIn = nil
                    }
                } else if type == "mate" {
                    let mateScore = raw > 0 ? 100_000 - raw : -100_000 - raw
                    score = mateScore
                    if multipv == 1 {
                        currentEvaluation = raw > 0 ? 1000 : -1000
                        currentMateIn = raw
                    }
                }
                index += 3
                continue
            }

            if token == "pv", index + 1 < tokens.count {
                pvMove = tokens[index + 1]
                pvLineMoves = Array(tokens[(index + 1)...])
                break
            }

            index += 1
        }

        guard let score, let pvMove else { return }
        latestDepth = max(latestDepth, depth)
        upsertPVLine(multipv: multipv, line: PVLine(move: pvMove, score: score, depth: depth, line: pvLineMoves))
    }

    private func upsertPVLine(multipv: Int, line: PVLine) {
        if multipv <= 0 { return }
        let maxLines = max(5, min(8, multiPV))
        let targetIndex = multipv - 1
        if targetIndex >= maxLines { return }

        if targetIndex < pvLines.count {
            pvLines[targetIndex] = line
        } else {
            while currentTopMoves.count < targetIndex {
                pvLines.append(PVLine(move: "", score: Int.min, depth: 0, line: []))
            }
            pvLines.append(line)
        }

        pvLines = pvLines
            .filter { !$0.move.isEmpty }
            .prefix(maxLines)
            .map { $0 }
            .sorted { lhs, rhs in
                if abs(lhs.score) > 90_000 || abs(rhs.score) > 90_000 {
                    return lhs.score > rhs.score
                }
                return lhs.score > rhs.score
            }

        currentTopMoves = pvLines.map { ($0.move, $0.score) }
    }

    private func chooseHumanLikeMove(defaultMove: String?) -> String? {
        var candidates = Array(pvLines.prefix(max(3, min(multiPV, 5))))
        guard !candidates.isEmpty else { return defaultMove }

        let clampedDifficulty = max(0.05, min(profile.skill, 1.0))
        let tiltPenalty = profile.tiltFactor * (blunderRate * 0.2)
        let adjustedSkill = max(0.05, clampedDifficulty - tiltPenalty)
        let effectiveBlunderRate = max(0.0, min(profile.blunderRate + (1.0 - adjustedSkill) * 0.18, 0.82))
        blunderRate = effectiveBlunderRate

        if isLikelyEndgame(), selectedBot != nil {
            let reduction = (selectedBot?.endgameSkill ?? 0.5) * 0.08
            blunderRate = max(0.0, blunderRate - reduction)
        }

        if profile.aggression > 0.55 {
            candidates = candidates.sorted { lhs, rhs in
                if lhs.score == rhs.score { return lhs.depth > rhs.depth }
                return lhs.score > rhs.score
            }
        }

        if Double.random(in: 0...1) < blunderRate, candidates.count > 1 {
            let worseMoves = Array(candidates.dropFirst(1 + Int.random(in: 0..<(min(2, candidates.count - 1)))))
            if let blunderMove = worseMoves.randomElement()?.move {
                return blunderMove
            }
        }

        if shouldInjectTacticalBlunder(candidates: candidates) {
            if let tacticalBlunder = chooseTacticalBlunder(candidates: candidates) {
                return tacticalBlunder
            }
        }

        let weights = candidates.enumerated().map { idx, line in
            let rankWeight = pow(adjustedSkill, Double(idx))
            let scoreWeight = max(0.08, Double(line.score + 1400) / 2800.0)
            let positionalWeight = 0.35 + profile.positionalBias * 0.65
            let confidenceWeight = 0.45 + profile.confidence * 0.55
            let tacticWeight = 0.45 + profile.tacticalSharpness * 0.55
            return rankWeight * scoreWeight * positionalWeight * confidenceWeight * tacticWeight
        }
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else { return candidates.first?.move ?? defaultMove }

        var roll = Double.random(in: 0..<totalWeight)
        for (index, candidate) in candidates.enumerated() {
            roll -= weights[index]
            if roll <= 0 {
                return candidate.move
            }
        }

        return candidates.first?.move ?? defaultMove
    }

    private func loadOpeningBook() {
        guard let path = Bundle.main.path(forResource: "opening_book", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            openingBook = [:]
            return
        }

        if let weighted = try? JSONDecoder().decode([String: [BookMove]].self, from: data) {
            openingBook = weighted
            return
        }

        if let simple = try? JSONDecoder().decode([String: [String]].self, from: data) {
            openingBook = simple.mapValues { $0.map { BookMove(move: $0, weight: 1.0) } }
            return
        }

        openingBook = [:]
    }

    private func bookMove(for fen: String) -> String? {
        guard let moves = openingBook[fen], !moves.isEmpty else { return nil }
        let styled = applyOpeningStyle(moves: moves)
        let total = styled.reduce(0.0) { $0 + max(0.01, $1.weight) }
        var roll = Double.random(in: 0..<total)
        for move in styled {
            roll -= max(0.01, move.weight)
            if roll <= 0 {
                return move.move
            }
        }
        return styled.first?.move
    }

    private func applyOpeningStyle(moves: [BookMove]) -> [BookMove] {
        switch openingStyle {
        case .random:
            return moves
        case .aggressive, .gambit:
            return moves.enumerated().map { idx, move in
                let bonus = idx < 2 ? 1.35 : 0.9
                return BookMove(move: move.move, weight: move.weight * bonus)
            }
        case .defensive, .positional:
            return moves.enumerated().map { idx, move in
                let bonus = idx == 0 ? 1.3 : (idx < 3 ? 1.1 : 0.85)
                return BookMove(move: move.move, weight: move.weight * bonus)
            }
        }
    }

    private func stopSearchInternal() {
        stopWorkItem?.cancel()
        stopWorkItem = nil
        send(command: "stop")
        isThinking = false
        pendingCompletion = nil
    }

    private func stateRead<T>(_ block: () -> T) -> T {
        if DispatchQueue.getSpecific(key: stateQueueKey) != nil {
            return block()
        }
        return stateQueue.sync(execute: block)
    }

    private func mutateState(_ block: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: stateQueueKey) != nil {
            block()
            return
        }
        stateQueue.async(execute: block)
    }

    private func quickEvaluate(board: ChessBoard, for color: PieceColor) -> Int {
        let fen = board.generateFEN(activeColor: color)
        if let cached = evalHeuristicCache[fen] {
            return cached
        }

        var value = 0
        var centralControl = 0
        var development = 0
        var kingSafety = 0
        for row in 0..<8 {
            for col in 0..<8 {
                let position = Position(row: row, col: col)
                guard let piece = board.piece(at: position) else { continue }
                let pieceValue: Int
                switch piece.type {
                case .pawn: pieceValue = 100
                case .knight, .bishop: pieceValue = 300
                case .rook: pieceValue = 500
                case .queen: pieceValue = 900
                case .king: pieceValue = 0
                }
                value += piece.color == color ? pieceValue : -pieceValue

                if (2...5).contains(row) && (2...5).contains(col) {
                    centralControl += piece.color == color ? 8 : -8
                }
                if piece.type == .knight || piece.type == .bishop {
                    let developed = piece.color == .white ? row < 7 : row > 0
                    development += developed ? (piece.color == color ? 12 : -12) : 0
                }
                if piece.type == .king {
                    let unsafe = board.isSquareAttacked(position, by: piece.color.opposite)
                    if unsafe {
                        kingSafety += piece.color == color ? -30 : 30
                    }
                }
            }
        }
        value += centralControl + development + kingSafety
        evalHeuristicCache[fen] = value
        if evalHeuristicCache.count > 4096 {
            evalHeuristicCache.removeAll(keepingCapacity: true)
        }
        return value
    }

    private func bestMoveByStaticEval(on board: ChessBoard, for color: PieceColor) -> String? {
        let moves = board.allLegalMoves(for: color)
        var best: (move: String, score: Int)?
        for move in moves {
            var clone = board
            guard clone.move(from: move.0, to: move.1, color: color) != nil else { continue }
            let score = quickEvaluate(board: clone, for: color)
            let uci = move.0.algebraic + move.1.algebraic
            if best == nil || score > best!.score {
                best = (uci, score)
            }
        }
        return best?.move
    }

    private func classifyMove(
        played: String,
        bestMove: String,
        evalBefore: Int,
        evalAfter: Int,
        boardBefore: String
    ) -> MoveClassification {
        let gain = evalAfter - evalBefore
        if played == bestMove {
            if isBrilliantMove(played: played, fenBefore: boardBefore, evalBefore: evalBefore, evalAfter: evalAfter) {
                return .brilliant
            }
            if gain > 140 {
                return .great
            }
            if gain > 60 {
                return .excellent
            }
            return .best
        }

        let loss = max(0, evalBefore - evalAfter)
        if loss > 300 { return .blunder }
        if loss > 150 { return .mistake }
        if loss > 50 { return .inaccuracy }
        if loss < 20 { return .excellent }
        return .good
    }

    private func isBrilliantMove(played: String, fenBefore: String, evalBefore: Int, evalAfter: Int) -> Bool {
        guard let parsed = ChessBoard.parseMove(played) else { return false }
        var board = ChessBoard()
        board.loadFEN(fenBefore)
        let movingPiece = board.piece(at: parsed.from)
        let capturedPiece = board.piece(at: parsed.to)

        guard let movingPiece else { return false }
        let isSacrifice = (capturedPiece == nil) && (movingPiece.type == .queen || movingPiece.type == .rook || movingPiece.type == .bishop || movingPiece.type == .knight)
        let stayedWinning = evalAfter >= 200 || evalAfter >= evalBefore - 20
        return isSacrifice && stayedWinning
    }

    private func isLikelyEndgame() -> Bool {
        guard let fen = activeSearch?.fen else { return false }
        var board = ChessBoard()
        board.loadFEN(fen)
        return isEndgame(board: board)
    }

    private func scheduleStopSearch(for fen: String) {
        var board = ChessBoard()
        board.loadFEN(fen)
        let activeColor = activeColorFromFEN(fen)
        let legalMoves = board.allLegalMoves(for: activeColor).count
        let phaseMultiplier: Double = isEndgame(board: board) ? 1.28 : (legalMoves > 30 ? 0.9 : 1.08)
        let complexity = min(max(Double(legalMoves) / 30.0, 0.45), 1.45)
        let skillTime = 220.0 + profile.skill * 1250.0
        let pressurePenalty = (1.0 - profile.timePressurePerformance) * 180.0
        let base = (skillTime + pressurePenalty) * phaseMultiplier * complexity
        let variance = (Double.random(in: -1...1) * profile.timeVariance * 220.0)
        let thinkTime = Int(max(130.0, base + variance))

        stopWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.send(command: "stop")
        }
        stopWorkItem = item
        engineQueue.asyncAfter(deadline: .now() + .milliseconds(thinkTime), execute: item)
    }

    private func activeColorFromFEN(_ fen: String) -> PieceColor {
        let parts = fen.split(separator: " ")
        guard parts.count > 1 else { return .white }
        return parts[1] == "b" ? .black : .white
    }

    private func shouldInjectTacticalBlunder(candidates: [PVLine]) -> Bool {
        guard candidates.count > 2 else { return false }
        let tacticalVolatility = 1.0 - profile.tacticalSharpness
        let gap = max(0, candidates.first!.score - candidates[min(2, candidates.count - 1)].score)
        let tacticalRisk = min(1.0, Double(gap) / 500.0)
        let chance = blunderRate * 0.6 + tacticalVolatility * 0.35 + tacticalRisk * 0.2
        return Double.random(in: 0...1) < min(chance, 0.9)
    }

    private func chooseTacticalBlunder(candidates: [PVLine]) -> String? {
        let lower = Array(candidates.dropFirst())
        guard !lower.isEmpty else { return nil }
        let biased = lower.sorted { $0.score < $1.score }
        return biased.prefix(2).randomElement()?.move
    }

    private func summarizeReview(_ items: [GameReviewItem]) -> GameSummary {
        guard !items.isEmpty else {
            return GameSummary(accuracy: 0, blunders: 0, mistakes: 0, brilliants: 0, averageCentipawnLoss: 0)
        }

        var totalLoss = 0.0
        var blunders = 0
        var mistakes = 0
        var brilliants = 0
        var scoreBucket = 0.0

        for item in items {
            let loss = max(0, item.evalBefore - item.evalAfter)
            totalLoss += Double(loss)
            switch item.classification {
            case .blunder:
                blunders += 1
                scoreBucket += 0
            case .mistake:
                mistakes += 1
                scoreBucket += 25
            case .inaccuracy:
                scoreBucket += 55
            case .good:
                scoreBucket += 72
            case .excellent:
                scoreBucket += 84
            case .best:
                scoreBucket += 94
            case .great:
                scoreBucket += 97
            case .brilliant:
                brilliants += 1
                scoreBucket += 100
            }
        }

        let accuracy = max(0.0, min(100.0, scoreBucket / Double(items.count)))
        return GameSummary(
            accuracy: accuracy,
            blunders: blunders,
            mistakes: mistakes,
            brilliants: brilliants,
            averageCentipawnLoss: totalLoss / Double(items.count)
        )
    }

    private func maybeStartAutoPonder(from fen: String, selectedMove: String) {
        guard let parsedAI = ChessBoard.parseMove(selectedMove) else { return }
        var board = ChessBoard()
        board.loadFEN(fen)
        let aiColor = activeColorFromFEN(fen)
        guard board.move(from: parsedAI.from, to: parsedAI.to, color: aiColor) != nil else { return }
        let opponentColor = aiColor.opposite
        let opponentMoves = board.allLegalMoves(for: opponentColor)
        guard let opponentLikely = opponentMoves.first else { return }
        let expectedOpponentMove = opponentLikely.0.algebraic + opponentLikely.1.algebraic

        var nextBoard = board
        guard nextBoard.move(from: opponentLikely.0, to: opponentLikely.1, color: opponentColor) != nil else { return }
        let responseFen = nextBoard.generateFEN(activeColor: aiColor)
        let predictedReply = bestMoveByStaticEval(on: nextBoard, for: aiColor)

        ponderPositionFen = responseFen
        ponderExpectedOpponentMove = expectedOpponentMove
        ponderCachedReplyMove = predictedReply
    }
}
