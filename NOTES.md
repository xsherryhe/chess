Basic game  
  -Piece class with descendants for each type
    -name, color/player, base_moves, legal_next_pos (method), position, can_jump, basic move method, special methods for special moves
  -Game class with players, board (array of pieces), play/take turn/evaluate game method
    -Option to resign, propose draw, or view instructions after every turn
  -Evaluate game module
    -Evalute if pawn is in last row and must transform
    -Evaluate check
    -Evaluate checkmate (2 checks)
    -Evaluate stalemate
    -Evaluate special game end conditions
      -Repetition of moves more than 3 times (player to move claims draw)
      -No pawn move/no capture in the last 50 moves (player to move claims draw)

Save state
  -Save the board with all the info about the pieces
Testing
