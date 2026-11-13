from abc import ABC, abstractmethod
from enum import Enum
from tkinter import *

class Game:
    def __init__(self):
        self.board = [King(0, Color.WHITE), Knight(1, Color.WHITE), Rook(2, Color.WHITE),
                                                            None, None,
                      Rook(5, Color.BLACK), Knight(6, Color.BLACK), King(7, Color.BLACK)]
        self.move = Color.WHITE
        self.circles, self.pieces = [], []
        self.cord = lambda evt: evt if type(evt) == int else evt.x // square_size
        self.draw_piece()
        self.selected = None
        canvas.bind("<Button-1>", self.on_click)

    def on_click(self, evt):
        if self.selected is None:
            self.first_click(evt)
        else:
            self.second_click(evt, *self.selected)

    def draw_piece(self):
        for piece in self.pieces:
            canvas.delete(piece)
        self.pieces = []
        for square in self.board:
            if isinstance(square, Piece):
                self.pieces.append(canvas.create_text(square_size * (square.cords + 0.5), square_size / 2, text=square.shape,
                                   font=('Times New Roman', square_size // 2), fill=str(square.color)))

    def first_click(self, evt):
        cord = self.cord(evt)
        piece = self.board[self.cord(evt)]
        if not isinstance(piece, Piece) or self.move != piece.color:
            return
        moves = self.possible_moves(piece.get_moves(self.board), piece)
        for move in moves:
            self.circles.append(canvas.create_oval(square_size * (move + 0.6), square_size * 0.4, square_size * (move + 0.4),
                               square_size * 0.6, fill='light green'))
        self.selected = (moves, cord)

    def possible_moves(self, moves, piece):
        res = []
        for move in moves:
            if not isinstance(self.board[move], Piece) or self.board[move].color != piece.color:
                board_copy = [square for square in self.board]
                piece_cords = piece.cords
                self.move_piece(piece_cords, move)
                in_check = self.check(piece.color)
                self.move_piece(move, piece_cords)
                self.board = board_copy
                if not in_check:
                    res.append(move)
        return res

    def move_piece(self, cord1, cord2):
        self.board[cord1].cords = cord2
        self.board[cord1], self.board[cord2] = None, self.board[cord1]

    def second_click(self, evt, moves, cord1):
        state = None
        for circle in self.circles:
            canvas.delete(circle)
        self.circles = []
        cord2 = self.cord(evt)
        if isinstance(self.board[cord2], Piece) and self.board[cord2].color == self.move:
            self.first_click(evt)
            return
        if cord2 in moves:
            self.move_piece(cord1, cord2)
            self.move = ~self.move
            self.draw_piece()
            if all(self.draw(piece) for piece in self.board
                    if isinstance(piece, Piece) and piece.color == self.move):
                if self.check(self.move):
                    state = f'checkmate\n{~self.move} won'
                else:
                    state = 'draw'

        self.selected = None
        if state:
            canvas.delete(ALL)
            canvas.create_text(square_size * 4, square_size // 2, text=state,
                               font=('Times New Roman', square_size // 3), fill='light green')
            tk.after(1_000, tk.destroy)

    def check(self, color):
        king_cords = None
        for i in range(8):
            if isinstance(self.board[i], King) and self.board[i].color == color:
                king_cords = i
                break
        for square in self.board:
            if isinstance(square, Piece) and square.color != color:
                if king_cords in square.get_moves(self.board):
                    break
        else:
            return False
        return True

    def draw(self, piece):
        return self.possible_moves(piece.get_moves(self.board), piece) == []

class Color(Enum):
    WHITE = 'white'
    BLACK = 'black'

    def __invert__(self):
        return Color.BLACK if self is Color.WHITE else Color.WHITE

    def __str__(self):
        return 'black' if self is Color.BLACK else 'white'

class Piece(ABC):
    def __init__(self, shape, cords, color: Color):
        self.shape = shape
        self.color = color
        self.cords = cords

    def __str__(self):
        return self.shape

    @abstractmethod
    def get_moves(self, board) -> list[int]:
        pass

class King(Piece):
    def __init__(self, cords, color: Color):
        super().__init__('♚', cords, color)

    def get_moves(self, board) -> list[int]:
        moves = []
        if self.cords < 7:
            moves.append(self.cords + 1)
        if self.cords > 0:
            moves.append(self.cords - 1)
        return moves

class Knight(Piece):
    def __init__(self, cords, color: Color):
        super().__init__('♞', cords, color)

    def get_moves(self, board) -> list[int]:
        moves = []
        if self.cords < 6:
            moves.append(self.cords + 2)
        if self.cords > 1:
            moves.append(self.cords - 2)
        return moves

class Rook(Piece):
    def __init__(self, cords, color: Color):
        super().__init__('♜', cords, color)

    def get_moves(self, board) -> list[int]:
        res = []
        for direction in (-1, 1):
            i = self.cords + direction
            while 0 <= i < 8:
                if isinstance(board[i], Piece):
                    if board[i].color != self.color:
                        res.append(i)
                    break
                res.append(i)
                i += direction
        return res


tk = Tk()
tk.title("1D Chess")
tk.wm_attributes("-topmost", 1)
tk.resizable(False, False)
tk.wm_protocol("WM_DELETE_WINDOW", tk.destroy)

square_size = 80
canvas = Canvas(tk, width=square_size * 8, height=square_size, bg='grey22')
for x in range(8):
    canvas.create_rectangle(x * square_size, 0, (x + 1) * square_size, square_size,
                            fill='brown' if x % 2 else 'grey22')
    canvas.create_text(square_size * (x + 0.8), square_size * 0.8, text=chr(ord('a') + x))
canvas.pack()

game = Game()

canvas.mainloop()
