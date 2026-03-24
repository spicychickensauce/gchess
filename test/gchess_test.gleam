import game
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import move_san
import pgn
import piece
import position
import status.{Draw, InProgress, ThreefoldRepetition}

pub fn main() {
  gleeunit.main()
}

pub fn perft_1_test() {
  let assert Ok(game) =
    game.from_fen_string(
      "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
    )
  assert perft(game, 2) == 2039
}

pub fn perft_2_test() {
  let assert Ok(game) =
    game.from_fen_string(
      "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
    )

  assert perft(game, 2) == 264
}

pub fn perft_3_test() {
  let assert Ok(game) =
    game.from_fen_string("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1")
  assert perft(game, 3) == 2812
}

pub fn perft_4_test() {
  let assert Ok(game) =
    game.from_fen_string("8/3k4/8/2BKB3/2PRP3/8/8/8 w - - 0 1")
  assert perft(game, 3) == 1445
}

fn perft(game, depth) {
  case depth {
    0 -> 1
    _ -> {
      let assert Ok(moves) = game.all_legal_moves(game)
      let nodes =
        list.fold(moves, 0, fn(nodes, move) {
          let assert Ok(game) = game.apply_move_raw(game, move)
          let nodes = nodes + perft(game, depth - 1)

          let assert Ok(_) = game.undo_move(game)
          nodes
        })
      nodes
    }
  }
}

pub fn move_san_from_string_test() {
  let assert Ok(move) = move_san.from_string("e4")

  move
  |> should.equal(move_san.Normal(
    moving_piece: piece.Pawn,
    from: None,
    to: position.Position(file: position.E, rank: position.Four),
    capture: False,
    promotion: None,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("R1a3")

  move
  |> should.equal(move_san.Normal(
    moving_piece: piece.Rook,
    from: Some(move_san.PositionSan(file: None, rank: Some(position.One))),
    to: position.Position(file: position.A, rank: position.Three),
    capture: False,
    promotion: None,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("Rxa3")
  move
  |> should.equal(move_san.Normal(
    moving_piece: piece.Rook,
    from: None,
    to: position.Position(file: position.A, rank: position.Three),
    capture: True,
    promotion: None,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("Qh4e1")
  move
  |> should.equal(move_san.Normal(
    moving_piece: piece.Queen,
    from: Some(move_san.PositionSan(
      file: Some(position.H),
      rank: Some(position.Four),
    )),
    to: position.Position(file: position.E, rank: position.One),
    capture: False,
    promotion: None,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("0-0")
  move
  |> should.equal(move_san.Castle(
    side: move_san.KingSide,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("0-0-0")
  move
  |> should.equal(move_san.Castle(
    side: move_san.QueenSide,
    maybe_check_or_checkmate: None,
  ))
}

pub fn load_pgn_into_game_test() {
  let pgn = "1. e4 e5 2. Bd3 Bd6 3. Nf3 Nf6 4. O-O"
  let assert Ok(game) = game.load_pgn(pgn)
  case game.status {
    Some(InProgress(fifty_move_rule: 5, threefold_repetition_rule: _)) -> True
    _ -> False
  }
  |> should.equal(True)
}

pub fn split_movetext_test() {
  let pgn = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O"
  let moves = pgn.split_movetext(pgn)
  moves
  |> should.equal(["e4 e5", "Nf3 Nc6", "Bb5 a6", "Ba4 Nf6", "O-O"])
}

pub fn threefold_repetition_rule_test() {
  let game = game.new_game()
  let game =
    apply_uci_moves(game, ["e2e4", "e7e5", "f1e2", "f8e7", "e2f1", "e7f8"])
  let assert Ok(_) = game.print_board(game)
  case game.status {
    Some(InProgress(_, _)) -> True
    _ -> False
  }
  |> should.equal(True)
  let game = apply_uci_moves(game, ["f1e2", "f8e7", "e2f1", "e7f8"])
  let assert Ok(_) = game.print_board(game)
  case game.status {
    Some(InProgress(_, _)) -> True
    _ -> False
  }
  |> should.equal(True)
  let game = apply_uci_moves(game, ["f1e2", "f8e7", "e2f1", "e7f8"])
  let assert Ok(_) = game.print_board(game)
  game.status
  |> should.equal(Some(Draw(ThreefoldRepetition)))
}

fn apply_uci_moves(game, moves) {
  use game, move <- list.fold(moves, game)
  let assert Ok(game) = game.apply_move_uci(game, move)
  game
}
