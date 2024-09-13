//
//  ContentView.swift
//  SummonShogiClassic
//
//  Created by 森田健太 on 9/13/24.
//

import SwiftUI

// 駒のモデル
struct Piece {
    var type: String?
    var isOpponent: Bool
    var isPromoted: Bool
    var position: (Int, Int)?
}

// メインのビュー
struct ContentView: View {
    @State private var highlightPositions: [(Int, Int)] = []
    @State private var board: [[Piece]] = Array(repeating: Array(repeating: Piece(type: nil, isOpponent: false, isPromoted: false), count: 9), count: 9)
    @State private var kingPosition: (Int, Int) = (8, 4)
    @State private var opponentKingPosition: (Int, Int) = (0, 4)
    @State private var isPlayerTurn: Bool = true // true for player, false for opponent
    @State private var summonedPiece: String? = nil
    @State private var isSummoning: Bool = false
    @State private var isPlacingCapturedPiece: Bool = false
    @State private var lastMovePosition: (Int, Int) = (8, 4)
    @State private var selectedPiecePosition: (Int, Int)? = nil
    @State private var playerCapturedPieces: [String] = []
    @State private var opponentCapturedPieces: [String] = []
    @State private var gameResult: String? = "勝利"
    @State private var isCheckmate: Bool = false
    @State private var showPromotionDialog: Bool = false
    @State private var promotionPosition: (Int, Int)? = nil
    @State private var isVisualizationOn: Bool = false
    @State private var kingMoveOptions: [(Int, Int)] = []
    @State private var opponentMoveOptions: [(Int, Int)] = []
    @State private var allMoveOptions: [(Int, Int)] = []

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            VStack(spacing: 3) {
                HeaderView(
                    resetAction: resetBoard,
                    isCheckmate: isCheckmate,
                    gameResult: gameResult,
                    isPlayerTurn: isPlayerTurn,
                    isVisualizationOn: $isVisualizationOn,
                    toggleVisualization: toggleVisualization
                )
                
                SummonButtonView(
                    summonedPiece: summonedPiece,
                    isPlayerTurn: isPlayerTurn,
                    isDisabled: isPlayerTurn || gameResult != nil,
                    action: summonPiece
                )
                
                CapturedPiecesView(
                    capturedPieces: opponentCapturedPieces,
                    isOpponent: true,
                    isPlayerTurn: isPlayerTurn,
                    summonedPiece: $summonedPiece,
                    isSummoning: $isSummoning,
                    isPlacingCapturedPiece: $isPlacingCapturedPiece,
                    board: $board,
                    highlightPositions: $highlightPositions,
                    capturedPiecesBinding: $opponentCapturedPieces
                )
                
                BoardView(
                    board: $board,
                    highlightPositions: $highlightPositions,
                    lastMovePosition: $lastMovePosition,
                    selectedPiecePosition: $selectedPiecePosition,
                    isPlayerTurn: $isPlayerTurn,
                    summonedPiece: $summonedPiece,
                    isSummoning: $isSummoning,
                    isPlacingCapturedPiece: $isPlacingCapturedPiece,
                    kingPosition: $kingPosition,
                    opponentKingPosition: $opponentKingPosition,
                    playerCapturedPieces: $playerCapturedPieces,
                    opponentCapturedPieces: $opponentCapturedPieces,
                    gameResult: $gameResult,
                    highlightPieceMoves: highlightPieceMoves,
                    checkForCheckmate: checkForCheckmate,
                    showPromotionDialog: $showPromotionDialog,
                    promotionPosition: $promotionPosition,
                    isVisualizationOn: $isVisualizationOn,
                    kingMoveOptions: $kingMoveOptions,
                    opponentMoveOptions: $opponentMoveOptions,
                    allMoveOptions: $allMoveOptions
                )
                
                CapturedPiecesView(
                    capturedPieces: playerCapturedPieces,
                    isOpponent: false,
                    isPlayerTurn: isPlayerTurn,
                    summonedPiece: $summonedPiece,
                    isSummoning: $isSummoning,
                    isPlacingCapturedPiece: $isPlacingCapturedPiece,
                    board: $board,
                    highlightPositions: $highlightPositions,
                    capturedPiecesBinding: $playerCapturedPieces
                )
                
                SummonButtonView(
                    summonedPiece: summonedPiece,
                    isPlayerTurn: isPlayerTurn,
                    isDisabled: !isPlayerTurn || gameResult != nil,
                    action: summonPiece
                )
                
                if let result = gameResult {
                    GameResultView(result: result, resetAction: resetBoard)
                }
                
                Spacer()
            }
            .padding(.vertical, 3)
            .onAppear {
                resetBoard()
            }
            
            if isCheckmate {
                Text("詰み")
                    .font(.system(size: 100))
                    .foregroundColor(.red)
                    .bold()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(10)
            }
            
            if showPromotionDialog, let promotionPos = promotionPosition {
                PromotionDialogView(
                    isShowing: $showPromotionDialog,
                    board: $board,
                    position: promotionPos,
                    onPromotionComplete: {
                        isPlayerTurn.toggle() // 手番交代
                        checkForCheckmate()
                    }
                )
            }
        }
    }

    // 以下、必要な関数を定義
    func resetBoard() {
        // ボードと状態の初期化
        highlightPositions = []
        board = Array(repeating: Array(repeating: Piece(type: nil, isOpponent: false, isPromoted: false), count: 9), count: 9)
        kingPosition = (8, 4)
        opponentKingPosition = (0, 4)
        isPlayerTurn = true
        summonedPiece = nil
        isSummoning = false
        isPlacingCapturedPiece = false
        lastMovePosition = (8, 4)
        selectedPiecePosition = nil
        playerCapturedPieces = []
        opponentCapturedPieces = []
        gameResult = nil
        isCheckmate = false
        showPromotionDialog = false
        promotionPosition = nil
        isVisualizationOn = false
        kingMoveOptions = []
        opponentMoveOptions = []
        allMoveOptions = []
        // 玉と王を配置
        board[kingPosition.0][kingPosition.1] = Piece(type: "玉", isOpponent: false, isPromoted: false)
        board[opponentKingPosition.0][opponentKingPosition.1] = Piece(type: "王", isOpponent: true, isPromoted: false)
    }

    func summonPiece() {
        // 駒の召喚ロジック
        let pieces = ["歩", "香", "桂", "銀", "金", "角", "飛"]
        let weights = [10, 5, 5, 4, 3, 2, 2]
        let totalWeight = weights.reduce(0, +)
        let randomValue = Int.random(in: 0..<totalWeight)

        var cumulativeWeight = 0
        for (index, weight) in weights.enumerated() {
            cumulativeWeight += weight
            if randomValue < cumulativeWeight {
                let pieceType = pieces[index]
                if canSummonPiece(pieceType) {
                    summonedPiece = pieceType
                    isSummoning = true
                    highlightPositions = []
                    for row in 0..<9 {
                        for col in 0..<9 {
                            if board[row][col].type == nil {
                                highlightPositions.append((row, col))
                            }
                        }
                    }
                    break
                }
            }
        }
    }

    func canSummonPiece(_ pieceType: String) -> Bool {
        let maxCounts = ["歩": 18, "香": 4, "桂": 4, "銀": 4, "金": 4, "角": 2, "飛": 2]
        let currentCount = board.flatMap { $0 }.filter { $0.type == pieceType }.count
        return currentCount < (maxCounts[pieceType] ?? 0)
    }

    func highlightPieceMoves(_ piece: Piece, at position: (Int, Int)) {
        // 駒の移動可能範囲を計算
        highlightPositions = []
        var moves: [(Int, Int)] = []

        switch piece.type {
        case "歩":
            moves = piece.isOpponent ? [(1, 0)] : [(-1, 0)]
        case "香":
            moves = piece.isOpponent ? generateLinearMoves(from: position, direction: (1, 0)) : generateLinearMoves(from: position, direction: (-1, 0))
        case "桂":
            moves = piece.isOpponent ? [(2, 1), (2, -1)] : [(-2, 1), (-2, -1)]
        case "銀":
            moves = piece.isOpponent ? [(1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)] : [(-1, 0), (-1, 1), (-1, -1), (1, 1), (1, -1)]
        case "金", "と", "杏", "圭", "全":
            moves = piece.isOpponent ? [(1, 0), (1, 1), (1, -1), (0, 1), (0, -1), (-1, 0)] : [(-1, 0), (-1, 1), (-1, -1), (0, 1), (0, -1), (1, 0)]
        case "角":
            moves = generateDiagonalMoves(from: position)
        case "馬":
            let diagonalMoves = generateDiagonalMoves(from: position)
            let additionalMoves = [(-1, -1), (-1, 0), (-1, 1)]
            moves = diagonalMoves + additionalMoves
        case "飛":
            moves = generateLinearMoves(from: position, direction: (1, 0)) +
                    generateLinearMoves(from: position, direction: (-1, 0)) +
                    generateLinearMoves(from: position, direction: (0, 1)) +
                    generateLinearMoves(from: position, direction: (0, -1))
        case "竜":
            let rookMoves = generateLinearMoves(from: position, direction: (1, 0)) +
                            generateLinearMoves(from: position, direction: (-1, 0)) +
                            generateLinearMoves(from: position, direction: (0, 1)) +
                            generateLinearMoves(from: position, direction: (0, -1))
            let kingMoves = [(-1, -1), (-1, 0), (-1, 1)]
            moves = rookMoves + kingMoves
        case "玉", "王":
            moves = [(-1, -1), (-1, 0), (-1, 1),
                     (0, -1),         (0, 1),
                     (1, -1),  (1, 0),  (1, 1)]
        default:
            moves = []
        }

        for move in moves {
            let newRow = position.0 + move.0
            let newCol = position.1 + move.1
            if newRow >= 0 && newRow < 9 && newCol >= 0 && newCol < 9 {
                let targetPiece = board[newRow][newCol]
                if targetPiece.type == nil || targetPiece.isOpponent != piece.isOpponent {
                    highlightPositions.append((newRow, newCol))
                }
            }
        }
    }

    func generateLinearMoves(from position: (Int, Int), direction: (Int, Int)) -> [(Int, Int)] {
        var moves: [(Int, Int)] = []
        var currentPos = (position.0 + direction.0, position.1 + direction.1)
        while currentPos.0 >= 0 && currentPos.0 < 9 && currentPos.1 >= 0 && currentPos.1 < 9 {
            let targetPiece = board[currentPos.0][currentPos.1]
            if targetPiece.type != nil {
                if targetPiece.isOpponent != board[position.0][position.1].isOpponent {
                    moves.append((currentPos.0 - position.0, currentPos.1 - position.1))
                }
                break
            }
            moves.append((currentPos.0 - position.0, currentPos.1 - position.1))
            currentPos = (currentPos.0 + direction.0, currentPos.1 + direction.1)
        }
        return moves
    }

    func generateDiagonalMoves(from position: (Int, Int)) -> [(Int, Int)] {
        let directions = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        var moves: [(Int, Int)] = []
        for direction in directions {
            moves += generateLinearMoves(from: position, direction: direction)
        }
        return moves
    }

    func checkForCheckmate() {
        // シンプルな詰みの判定
        let kingPos = isPlayerTurn ? opponentKingPosition : kingPosition
        let kingPiece = board[kingPos.0][kingPos.1]
        var movesAvailable = false

        let moves = [(-1, -1), (-1, 0), (-1, 1),
                     (0, -1),         (0, 1),
                     (1, -1),  (1, 0),  (1, 1)]

        for move in moves {
            let newRow = kingPos.0 + move.0
            let newCol = kingPos.1 + move.1
            if newRow >= 0 && newRow < 9 && newCol >= 0 && newCol < 9 {
                let targetPiece = board[newRow][newCol]
                if targetPiece.type == nil || targetPiece.isOpponent != kingPiece.isOpponent {
                    movesAvailable = true
                    break
                }
            }
        }

        if !movesAvailable {
            gameResult = isPlayerTurn ? "先手勝利" : "後手勝利"
            isCheckmate = true
        }
    }

    func toggleVisualization() {
        isVisualizationOn.toggle()
        if isVisualizationOn {
            updateVisualization()
        } else {
            kingMoveOptions = []
            opponentMoveOptions = []
            allMoveOptions = []
        }
    }

    func updateVisualization() {
        kingMoveOptions = []
        opponentMoveOptions = []
        allMoveOptions = []

        let kingPos = isPlayerTurn ? kingPosition : opponentKingPosition
        let kingPiece = board[kingPos.0][kingPos.1]
        let moves = [(-1, -1), (-1, 0), (-1, 1),
                     (0, -1),         (0, 1),
                     (1, -1),  (1, 0),  (1, 1)]

        for move in moves {
            let newRow = kingPos.0 + move.0
            let newCol = kingPos.1 + move.1
            if newRow >= 0 && newRow < 9 && newCol >= 0 && newCol < 9 {
                let targetPiece = board[newRow][newCol]
                if targetPiece.type == nil || targetPiece.isOpponent != kingPiece.isOpponent {
                    kingMoveOptions.append((newRow, newCol))
                }
            }
        }

        for row in 0..<9 {
            for col in 0..<9 {
                let piece = board[row][col]
                if piece.type != nil {
                    highlightPieceMoves(piece, at: (row, col))
                    allMoveOptions.append(contentsOf: highlightPositions)
                }
            }
        }
    }
}

// ヘッダービュー
struct HeaderView: View {
    var resetAction: () -> Void
    var isCheckmate: Bool
    var gameResult: String?
    var isPlayerTurn: Bool
    @Binding var isVisualizationOn: Bool
    var toggleVisualization: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Summon Shogi")
                .font(.largeTitle)
                .foregroundColor(.black)
                .padding(.vertical, 1)
            Text("~召喚将棋〜")
                .font(.largeTitle)
                .foregroundColor(.black)
                .padding(.vertical, 0)
            HStack {
                Spacer()
                Button(action: {
                    resetAction()
                }) {
                    Image(systemName: "arrow.clockwise.circle")
                        .padding(.vertical, 3)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    toggleVisualization()
                }) {
                    Text(isVisualizationOn ? "可視化Off" : "可視化On")
                        .padding(.vertical, 3)
                        .background(isVisualizationOn ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            Text("詰み状況: \(isCheckmate ? "詰み" : "進行中"), 勝者: \(gameResult ?? "なし"), 手番: \(isPlayerTurn ? "先手" : "後手")")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(3)
                
        }
    }
}

// 召喚ボタンビュー
struct SummonButtonView: View {
    var summonedPiece: String?
    var isPlayerTurn: Bool
    var isDisabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(summonedPiece ?? "召")
                .padding(.all, 8)
                .background(isDisabled ? Color.gray : Color.orange)
                .foregroundColor(.white)
                .cornerRadius(16)
        }
        .disabled(isDisabled)
    }
}

// 持ち駒ビュー
struct CapturedPiecesView: View {
    var capturedPieces: [String]
    var isOpponent: Bool
    var isPlayerTurn: Bool
    @Binding var summonedPiece: String?
    @Binding var isSummoning: Bool
    @Binding var isPlacingCapturedPiece: Bool
    @Binding var board: [[Piece]]
    @Binding var highlightPositions: [(Int, Int)]
    @Binding var capturedPiecesBinding: [String]

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(capturedPieces, id: \.self) { piece in
                    Text(piece)
                        .frame(width: 40, height: 40)
                        .background(Color.purple.opacity(0.3))
                        .border(Color.black)
                        .rotationEffect(isOpponent ? .degrees(180) : .degrees(0))
                        .onTapGesture {
                            if (isOpponent && !isPlayerTurn && summonedPiece == nil) || (!isOpponent && isPlayerTurn && summonedPiece == nil) {
                                summonedPiece = piece
                                isSummoning = true
                                isPlacingCapturedPiece = true
                                highlightPositions = []
                                for row in 0..<9 {
                                    for col in 0..<9 {
                                        if board[row][col].type == nil {
                                            highlightPositions.append((row, col))
                                        }
                                    }
                                }
                                // 一時的に持ち駒から削除
                                if let index = capturedPiecesBinding.firstIndex(of: piece) {
                                    capturedPiecesBinding.remove(at: index)
                                }
                            }
                        }
                }
            }
        }
        .frame(height: 30)
        .padding(.vertical, 3)
    }
}

// 将棋盤ビュー
struct BoardView: View {
    @Binding var board: [[Piece]]
    @Binding var highlightPositions: [(Int, Int)]
    @Binding var lastMovePosition: (Int, Int)
    @Binding var selectedPiecePosition: (Int, Int)?
    @Binding var isPlayerTurn: Bool
    @Binding var summonedPiece: String?
    @Binding var isSummoning: Bool
    @Binding var isPlacingCapturedPiece: Bool
    @Binding var kingPosition: (Int, Int)
    @Binding var opponentKingPosition: (Int, Int)
    @Binding var playerCapturedPieces: [String]
    @Binding var opponentCapturedPieces: [String]
    @Binding var gameResult: String?
    var highlightPieceMoves: (Piece, (Int, Int)) -> Void
    var checkForCheckmate: () -> Void
    @Binding var showPromotionDialog: Bool
    @Binding var promotionPosition: (Int, Int)?
    @Binding var isVisualizationOn: Bool
    @Binding var kingMoveOptions: [(Int, Int)]
    @Binding var opponentMoveOptions: [(Int, Int)]
    @Binding var allMoveOptions: [(Int, Int)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        CellView(
                            row: row,
                            col: col,
                            board: $board,
                            highlightPositions: $highlightPositions,
                            lastMovePosition: $lastMovePosition,
                            selectedPiecePosition: $selectedPiecePosition,
                            isPlayerTurn: $isPlayerTurn,
                            summonedPiece: $summonedPiece,
                            isSummoning: $isSummoning,
                            isPlacingCapturedPiece: $isPlacingCapturedPiece,
                            kingPosition: $kingPosition,
                            opponentKingPosition: $opponentKingPosition,
                            playerCapturedPieces: $playerCapturedPieces,
                            opponentCapturedPieces: $opponentCapturedPieces,
                            gameResult: $gameResult,
                            highlightPieceMoves: highlightPieceMoves,
                            checkForCheckmate: checkForCheckmate,
                            showPromotionDialog: $showPromotionDialog,
                            promotionPosition: $promotionPosition,
                            isVisualizationOn: $isVisualizationOn,
                            kingMoveOptions: $kingMoveOptions,
                            opponentMoveOptions: $opponentMoveOptions,
                            allMoveOptions: $allMoveOptions
                        )
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}

// マス目ビュー
struct CellView: View {
    var row: Int
    var col: Int
    @Binding var board: [[Piece]]
    @Binding var highlightPositions: [(Int, Int)]
    @Binding var lastMovePosition: (Int, Int)
    @Binding var selectedPiecePosition: (Int, Int)?
    @Binding var isPlayerTurn: Bool
    @Binding var summonedPiece: String?
    @Binding var isSummoning: Bool
    @Binding var isPlacingCapturedPiece: Bool
    @Binding var kingPosition: (Int, Int)
    @Binding var opponentKingPosition: (Int, Int)
    @Binding var playerCapturedPieces: [String]
    @Binding var opponentCapturedPieces: [String]
    @Binding var gameResult: String?
    var highlightPieceMoves: (Piece, (Int, Int)) -> Void
    var checkForCheckmate: () -> Void
    @Binding var showPromotionDialog: Bool
    @Binding var promotionPosition: (Int, Int)?
    @Binding var isVisualizationOn: Bool
    @Binding var kingMoveOptions: [(Int, Int)]
    @Binding var opponentMoveOptions: [(Int, Int)]
    @Binding var allMoveOptions: [(Int, Int)]

    
    var body: some View {
        let isHighlighted = highlightPositions.contains { $0 == (row, col) }
        let isLastMove = lastMovePosition == (row, col)
        let piece = board[row][col]
        let isKingMoveOption = kingMoveOptions.contains { $0 == (row, col) }
        let isOpponentMoveOption = opponentMoveOptions.contains { $0 == (row, col) }
        let isAllMoveOption = allMoveOptions.contains { $0 == (row, col) }
        
        // 背景色の計算をまとめる
        let backgroundColor: Color = {
            if isLastMove {
                return Color.red.opacity(0.3)
            } else if isHighlighted {
                return Color.green.opacity(0.5)
            } else if isKingMoveOption {
                return Color.yellow.opacity(0.5)
            } else if isOpponentMoveOption {
                return Color.red.opacity(0.5)
            } else if isAllMoveOption {
                return Color.blue.opacity(0.5)
            } else if piece.type != nil && piece.isOpponent == isPlayerTurn {
                return Color.blue.opacity(0.5)
            } else {
                return Color.orange.opacity(0.3)
            }
        }()
        
        // まとめた背景色を使用
        Text(piece.type ?? "")
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .border(Color.black)
            .rotationEffect(piece.isOpponent ? .degrees(180) : .degrees(0))
            .foregroundColor(.black)
            .onTapGesture {
                if gameResult != nil { return }
                if isHighlighted, let selectedPosition = selectedPiecePosition {
                    // 駒の捕獲と移動の処理
                    let targetPiece = board[row][col]
                    if let targetType = targetPiece.type, targetPiece.isOpponent != board[selectedPosition.0][selectedPosition.1].isOpponent {
                        // 持ち駒に追加
                        if isPlayerTurn {
                            playerCapturedPieces.append(demotePiece(targetType))
                        } else {
                            opponentCapturedPieces.append(demotePiece(targetType))
                        }
                    }
                    // 駒の移動
                    var movingPiece = board[selectedPosition.0][selectedPosition.1]
                    movingPiece.position = (row, col)
                    board[row][col] = movingPiece
                    board[selectedPosition.0][selectedPosition.1] = Piece(type: nil, isOpponent: false, isPromoted: false)
                    selectedPiecePosition = nil
                    highlightPositions = []
                    lastMovePosition = (row, col)
                    if movingPiece.type == "玉" {
                        kingPosition = (row, col)
                    } else if movingPiece.type == "王" {
                        opponentKingPosition = (row, col)
                    }
                    // 成り判定
                    if shouldPromote(piece: movingPiece, to: (row, col)) {
                        promotionPosition = (row, col)
                        showPromotionDialog = true
                    } else {
                        isPlayerTurn.toggle() // 手番交代
                        checkForCheckmate()
                    }
                } else if isHighlighted && isSummoning {
                    // 召喚した駒を配置
                    board[row][col] = Piece(type: summonedPiece, isOpponent: !isPlayerTurn, isPromoted: false)
                    if isPlacingCapturedPiece {
                        isPlacingCapturedPiece = false
                    }
                    summonedPiece = nil
                    isSummoning = false
                    highlightPositions = []
                    lastMovePosition = (row, col)
                    isPlayerTurn.toggle() // 手番交代
                    checkForCheckmate()
                } else if !isHighlighted && piece.type != nil && piece.isOpponent == !isPlayerTurn {
                    // 駒を選択
                    selectedPiecePosition = (row, col)
                    highlightPieceMoves(piece, (row, col))
                } else if isHighlighted && !isSummoning {
                    // 選択を解除
                    selectedPiecePosition = nil
                    highlightPositions = []
                }
            }
    }
    
//    var body: some View {
//        let isHighlighted = highlightPositions.contains { $0 == (row, col) }
//        let isLastMove = lastMovePosition == (row, col)
//        let piece = board[row][col]
//        let isKingMoveOption = kingMoveOptions.contains { $0 == (row, col) }
//        let isOpponentMoveOption = opponentMoveOptions.contains { $0 == (row, col) }
//        
//        Text(piece.type ?? "")
//            .frame(width: 40, height: 40)
//            .background(isLastMove ? Color.red.opacity(0.3) : (isHighlighted ? Color.green.opacity(0.5) : (isKingMoveOption ? Color.yellow.opacity(0.5) : (isOpponentMoveOption ? Color.blue.opacity(0.5) : Color.orange.opacity(0.3)))))
//            .border(Color.black)
//            .rotationEffect(piece.isOpponent ? .degrees(180) : .degrees(0))
//            .foregroundColor(.black)
//            .onTapGesture {
//                if gameResult != nil { return }
//                if isHighlighted, let selectedPosition = selectedPiecePosition {
//                    // 駒の捕獲
//                    let targetPiece = board[row][col]
//                    if let targetType = targetPiece.type, targetPiece.isOpponent != board[selectedPosition.0][selectedPosition.1].isOpponent {
//                        // 持ち駒に追加
//                        if isPlayerTurn {
//                            playerCapturedPieces.append(demotePiece(targetType))
//                        } else {
//                            opponentCapturedPieces.append(demotePiece(targetType))
//                        }
//                    }
//                    // 駒の移動
//                    var movingPiece = board[selectedPosition.0][selectedPosition.1]
//                    
//                    movingPiece.position = (row, col)
//                    
//                    board[row][col] = movingPiece
//                    board[selectedPosition.0][selectedPosition.1] = Piece(type: nil, isOpponent: false, isPromoted: false)
//                    selectedPiecePosition = nil
//                    highlightPositions = []
//                    lastMovePosition = (row, col)
//                    if movingPiece.type == "玉" {
//                        kingPosition = (row, col)
//                    } else if movingPiece.type == "王" {
//                        opponentKingPosition = (row, col)
//                    }
//                    // 成りの判定
//                    if shouldPromote(piece: movingPiece, to: (row, col)) {
//                        promotionPosition = (row, col)
//                        showPromotionDialog = true
//                    } else {
//                        isPlayerTurn.toggle() // 手番を交代
//                        checkForCheckmate()
//                    }
//                } else if isHighlighted && isSummoning {
//                    // 召喚した駒を配置
//                    board[row][col] = Piece(type: summonedPiece, isOpponent: !isPlayerTurn, isPromoted: false)
//                    if isPlacingCapturedPiece {
//                        isPlacingCapturedPiece = false
//                    }
//                    summonedPiece = nil
//                    isSummoning = false
//                    highlightPositions = []
//                    lastMovePosition = (row, col)
//                    // 成りの判定はしない
//                    isPlayerTurn.toggle() // 手番を交代
//                    checkForCheckmate()
//                } else if !isHighlighted && piece.type != nil && piece.isOpponent == !isPlayerTurn {
//                    // 駒を選択
//                    selectedPiecePosition = (row, col)
//                    highlightPieceMoves(piece, (row, col))
//                } else if isHighlighted && !isSummoning {
//                    // 選択を解除
//                    selectedPiecePosition = nil
//                    highlightPositions = []
//                }
//            }
//    }
    
    func shouldPromote(piece: Piece, to position: (Int, Int)) -> Bool {
        if piece.isPromoted { return false }
        if piece.type == "金" { return false }
        if piece.isOpponent {
            return position.0 >= 6 && !isSummoning && !isPlacingCapturedPiece
        } else {
            return position.0 <= 2 && !isSummoning && !isPlacingCapturedPiece
        }
    }
    
    func demotePiece(_ pieceType: String) -> String {
        switch pieceType {
        case "と":
            return "歩"
        case "杏":
            return "香"
        case "圭":
            return "桂"
        case "全":
            return "銀"
        case "馬":
            return "角"
        case "竜":
            return "飛"
        default:
            return pieceType
        }
    }
}

// プロモーションダイアログビュー
struct PromotionDialogView: View {
    @Binding var isShowing: Bool
    @Binding var board: [[Piece]]
    var position: (Int, Int)
    var onPromotionComplete: () -> Void  // クロージャを追加

    var body: some View {
        VStack {
            Text("成りますか？")
                .font(.title)
                .foregroundColor(.black)
                .padding()
            HStack {
                Button("成る") {
                    switch board[position.0][position.1].type {
                    case "歩":
                        board[position.0][position.1].type = "と"
                    case "香":
                        board[position.0][position.1].type = "杏"
                    case "桂":
                        board[position.0][position.1].type = "圭"
                    case "銀":
                        board[position.0][position.1].type = "全"
                    case "角":
                        board[position.0][position.1].type = "馬"
                    case "飛":
                        board[position.0][position.1].type = "竜"
                    default:
                        break
                    }
                    board[position.0][position.1].isPromoted = true
                    isShowing = false
                    onPromotionComplete()  // 成りの完了時にクロージャを呼び出す
                }
                .padding()
                Button("成らない") {
                    isShowing = false
                    onPromotionComplete()  // クロージャを呼び出して手番を交代させる
                }
                .padding()
            }
        }
        .frame(width: 200, height: 100)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

// ゲーム結果ビュー
struct GameResultView: View {
    var result: String
    var resetAction: () -> Void

    var body: some View {
        VStack {
            Text(result)
                .font(.largeTitle)
                .padding()
            Button("もう一度プレイ") {
                resetAction()
            }
            .padding()
        }
    }
}
