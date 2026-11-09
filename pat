from abc import ABC, abstractmethod
from copy import deepcopy
from tkinter import *

class Game:
    def __init__(self):
        self.board = [King(0, 'white'), Knight(1, 'white'), Rook(2, 'white'),
                                                            None, None,
                      Rook(5, 'black'), Knight(6, 'black'), King(7, 'black')]
        self.move = 'white'
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
                                   font=('Times New Roman', square_size // 2), fill=square.color))

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
                res.append(move)
        return res

    def second_click(self, evt, moves, cord1, draw_check=False):
        for circle in self.circles:
            canvas.delete(circle)
        self.circles = []
        cord2 = self.cord(evt)
        if cord2 in moves:
            self.board[cord1].cords = cord2
            self.board[cord1], self.board[cord2] = None, self.board[cord1]
            self.draw_piece()
            if not draw_check:
                print('is checking draw')
                self.move = 'white' if self.move == 'black' else 'black'
                self.draw()

        self.selected = None
        self.end_of_the_game()

    def check(self):
        king_cords = None
        for i in range(8):
            if isinstance(self.board[i], King) and self.board[i].color == self.move:
                king_cords = i
                break
        for square in self.board:
            if isinstance(square, Piece) and square.color != self.move:
                if king_cords in self.possible_moves(square.get_moves(self.board), square):
                    break
        else:
            return False
        return True

    def draw(self):
        king_cords = None
        board_copy = [square if square is None else type(square)(square.cords, square.color) for square in self.board]
        print(*((type(i), i.cords) for i in board_copy if isinstance(i, Piece)), 'first print')
        #board_copy = self.board.copy()
        #board_copy = deepcopy(self.board)
        for piece in self.board:
            self.board = [square if square is None else type(square)(square.cords, square.color) for square in board_copy]
            if isinstance(piece, Piece) and piece.color == self.move:
                moves = self.possible_moves(piece.get_moves(self.board), piece)
                for move in moves:
                    print(type(piece), move)
                    self.second_click(move, moves, piece.cords, True)
                    for i in range(8):
                        if isinstance(self.board[i], King) and self.board[i].color == self.move:
                            king_cords = i
                            break
                    for square in self.board:
                        if isinstance(square, Piece) and square.color != self.move:
                            if king_cords in self.possible_moves(square.get_moves(self.board), square):
                                break
                    else:
                        return False
        print(*((type(i), i.cords) for i in board_copy if isinstance(i, Piece)))
        self.board = board_copy

        print('draw')
        return True


    def end_of_the_game(self):
        kings = []
        for square in self.board:
            if isinstance(square, King):
                kings.append(square.color)
        if len(kings) == 1:
            tk.destroy()
            if 'white' not in kings:
                print('BLACK WON')
            else:
                print('WHITE WON')

class Piece(ABC):
    def __init__(self, shape, cords, color):
        self.shape = shape
        self.color = color
        self.cords = cords

    @abstractmethod
    def get_moves(self, board) -> list[int]:
        pass

class King(Piece):
    def __init__(self, cords, color):
        super().__init__('♚', cords, color)

    def get_moves(self, board) -> list[int]:
        moves = []
        if self.cords < 7:
            moves.append(self.cords + 1)
        if self.cords > 0:
            moves.append(self.cords - 1)
        return moves

class Knight(Piece):
    def __init__(self, cords, color):
        super().__init__('♞', cords, color)

    def get_moves(self, board) -> list[int]:
        moves = []
        if self.cords < 6:
            moves.append(self.cords + 2)
        if self.cords > 1:
            moves.append(self.cords - 2)
        return moves

class Rook(Piece):
    def __init__(self, cords, color):
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
canvas = Canvas(tk, width=square_size * 8, height=square_size)
for x in range(8):
    canvas.create_rectangle(x * square_size, 0, (x + 1) * square_size, square_size,
                            fill='brown' if x % 2 else 'grey22')
    canvas.create_text(square_size * (x + 0.8), square_size * 0.8, text=chr(ord('a') + x))
canvas.pack()

'''rep = type(King(0, 'white'))(1, 'black')
print(f'rep parameters: cords - {rep.cords}; color - {rep.color}')'''

game = Game()

canvas.mainloop()
