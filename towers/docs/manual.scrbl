#lang scribble/base

@; MULTI-PAGE ??

@(require scribble/manual
          racket/runtime-path)


@(define towers @bold{Towers})

@; OBSOLETE:
@(define (img-name->image name)
   (image (build-path 'up "img" name)))

@(define-runtime-path screenshot-5x5-annnotated 
   "../img-web/screenshot-5x5-annnotated.png"
;   (build-path 'up "img" "screenshot-5x5-annnotated.png"))
)

@title{@towers Rules}
@;author+email["Laurent Orseau" "laurent.orseau@gmail.com" #:obfuscate? #t]

@towers is a turn-by-turn, two-player board game like Chess, Draughts, and Go.
As such it is a strategy game, 
and incorporates a resource management part that makes it unique.

@;It is designed to be fun to play, but also to be a challenge to computer programs,
@;because @towers is inherently more complex (for computers!) than Chess and even Go!


The size of the board ranges from 5x5 to 10x10.

@(image screenshot-5x5-annnotated)


@(table-of-contents)


@section{Quick summary of the Official Rules}

Here is a summary of the rules.
Please read the following sections if it is not clear enough.

@; TODO: add hotlinks to the related sections!
@(itemlist
  @item{The goal of the game is to capture the opponent's master.}
  @item{The player has as many move points per turn as it has reserve pawns.}
  @item{The player can use all or less than its total amount of move points.}
  @item{Moving N pawns of M cells requires and uses N*M move points of the reserve.}
  @item{Pawns can move on the 4 adjacent cells, but can do so several times per turn,
        as long as the cell is not locked and there remain move points.}
  @item{A pawn can move onto another pawn/tower of the same player to form a higher tower.}
  @item{A pawn/tower can attack another pawn/tower of at most the same height. 
        The attacked pawn/tower is removed from the board.}
  @item{Attacking or raising a tower locks the destination cell.}
  @item{No further action can be done with a locked cell.
        A cell remains locked until the end of the player's turn.}
  @item{Unused move-points/reserve-pawns can be imported onto the master.}
  @item{Pawns can get out on the master tower one by one.}
  @item{At the end of the player's turn, any pawn on the player's master returns to the reserve 
        (even if the master is locked).}
  )

@section{Official Rules}

The goal is to capture the opponent's master pawn.

@;Each pawn can move on the 8 adjacent cells (or less if it is on a border of the board).
Each pawn can move on the 4 adjacent cells (or less if it is on a border of the board).

@;TODO: Initial placement of the pawns?

 @subsection{Reserve pawns and move points}

Move points are the number of pawns the player has in its reserve.
The initial number of reserve pawns per player is equal to the width of the board minus 4: 
6 on a 10x10 board, 5 on 9x9, ... and 1 on 5x5.
@;{Reason:
   6 on 10x10 means that a pawn cannot at the very beginning capture an opponent's pawn.
   (first ply is capture-less)
}

  Reserve pawns are placed outside of the board.
Pawns can be imported from the reserve to the board and vice-versa (see @secref{import-export}).

During a single turn, each player can make as many moves as it has move points.
It is up to the player to decide how these move points are used.

At the beginning of each turn, all the reserve pawns are placed on the left of the board.
Each time a move point is used, one reserve pawn is 
moved from the left side (yet unused reserve pawn side) 
to the right side (used reserve pawn side) of the board.

When the player has used all its move points in the current turn, 
its turn ends and its opponent's turn begins.

The player can also decide to end its turn prematurely by "passing";
it should then say "I pass" aloud.

 @subsection{Building and moving towers}
 
A single pawn can be moved several times in the same turn.
A pawn can move up, down, left or right as long as the player has sufficient move points 
and the cells it passes over are empty.
A (unlocked) pawn can move several times per turn, and thus can make an L-shaped move for example.

Towers are made of superimposed pawns.
A pawn is a tower of height 1.

To build a tower of height 2, simply move a pawn onto a another pawn of yours.
You can raise towers by putting one pawn at a time onto them.
It is not possible to put a tower onto another tower.

Moving a tower requires as many move points as the height of the tower.
For example, moving a tower of height 3 by 2 cells requires 6 move points.

 @subsection{Attacking the opponent's pawns and towers}
 
A tower T1 can be moved onto an opponent's tower T2, 
thus attacking it,
only if T1 is at least as high as T2.
Then T2 is removed from the board (it does not go to the reserve),
and T1 is placed on the cell where T2 was.

There is one notable exception to the removal rule:
If a tower or a pawn is captured by the master, 
then the master tower is raised by the number of captured pawns.
These captured pawns return to the attacker's reserve at the end of its turn.

The game ends when the opponent's master pawn is captured.

 @subsection[#:tag "locked-cells"]{Locked cells}
 
When a pawn is moved onto another pawn/tower (of any player),
i.e., by attacking a tower or raising a tower,
the target cell becomes @emph{locked}.
No further action of the current turn can involve a locked cell.
This means that a locked tower cannot move, 
cannot be raised and cannot attack.

A locked cell is indicated by:
@(define-runtime-path locked-cell
   "../img/locked-cell.png"
   ;(build-path 'up "img" "set2" "locked-cell.png")
   )
@(image locked-cell)



 @subsection[#:tag "import-export"]{Importing and exporting pawns}
 
 @subsubsection{Exporting pawns}
 
Any pawn that lies on top of the master at the end of the turn returns to the reserve.
This is called @emph{exporting pawns}.

This can be used to increase the number of reserve points for the next turn.
This also implies that the master tower is always of height 1 during the opponent's turn, 
and is thus always vulnerable to any opponent's pawn.
But the master can still be temporarily raised to a tower during the player's turn in order 
to attack an opponent's tower. Note that the captured tower is not removed from the board but is 
instead added to the master tower; hence the captured tower goes to the attacker's reserve at the 
end of the turn, giving the player a serious advantage.

As for normal towers, the master tower gets locked after a raise or an attack.

 @subsubsection{Importing pawns}
 
At any time during the player's turn, if the master's cell is not locked,
one or more reserve pawn can be @emph{imported} by placing it upon the master.
This cost 1 move point per imported pawn.
This does not lock the master's cell.

The master tower can then be used for attack, 
or imported pawns can be moved out of the master (right-click an drag) 
to an adjacent unlocked cell, one at a time.

 @subsubsection{Example}

For example, player A has 2 remaining move points.
It takes one of the points/reserve-pawns and places it on the master pawn
(thus importing and using a move point at the same time).
It now has a tower master of height 2, and 1 remaining move point.
Note: It is useless to import the last move point/reserve-pawn,
since there is no remaining move point to move it out of the master,
and thus the pawn returns to the reserve at the end of the turn.

@;(pictures ?!)
 


 @subsection{Draw game}
 
The game is a draw when each player passes one after the other,
or when two successive board positions have already been played exactly the same before.

At the end of a turn, 
if the configuration of the board is the same 
as the one at the beginning of the same turn, 
it is considered a "pass".

@section{How to Play in @towers Software}

To move one pawn or one tower, simply drag it with the left mouse button.
After that, if you have some remaining move points, you can move that same tower in another direction.

To import a pawn from the reserve onto the board, click on the "import" button.
It appears on the master.
You can then move it out of the master, by dragging it with the @emph{right} mouse button.

@;To export a pawn to the reserve, click on the export button.

Once you have used all your move points, your turn ends.
Click on the "End turn" button.
If you are playing over the net, your opponent will be informed that you have played.

If you want your turns to always end automatically, you can set that in the Edit/Preferences panel.

You can end your turn prematurely by pressing the "End turn" button if you don't need to use all your move points.

You can also resign a game by pressing the Resign button.

@section{Tips}

Towers resist more to attacks, but are also more difficult to move.
Keep in mind that it is not possible to take pawns out of towers, 
so don't build towers that you can't move!


Keep in mind that a single opponent pawn can move by several cells, 
and may not be so far away from your master pawn!

@;{
One move point is sometimes sufficient to add several pawns to the reserve:
If the master pawn moves onto a tower of the player, 
then the entire tower returns to the reserve at the end of the turn.
;}
  
Be sure to protect the master because at the end of the turn it returns
to a defense-less pawn, even if you raised it to a tower during your turn.

Also make sure your opponent cannot safely capture some of your pawns with its master,
otherwise this would increase its reserve!
In general, you should not have a lonely pawn that is not "covered" by another one.

@section{Specific Rules}

Beside the official rules, there are a number of alternative rules that can be played with.
You can select them in the dialog box when creating a new game.

Try them, these variants make @towers even more fun!

@;{
@section{Complexity of the Game}

The complexity of a board game can be roughly computed
by approximating the number of moves one player can do at each turn.

For Chess, the average number of moves per turn is considered to be
approximately 40 (37).
For Go, it is at worst 19*19=361 and around 100-250 on average.

For a 10x10 @towers game with initially 20 pawns on the board and 6 pawns in the reserve,
the number of possible moves for the first ply (turn) of the first player 
is less than (20*8)^6 ~ 16.000.000.000.000 ~ 10^13,
which is considerably far greater than that of Go!
It corresponds to approximately 5 plies of Go,
whereas a ply of Go roughly corresponds only to 1.5 ply of Chess.

At the beginning of the small 5x5 game however, 
the number of possible moves 
is less than 8*10 considering that each pawn can move on 8 cells 
(the actual value is 3*8+5*5+2*3=55).
But as soon as another pawn gets into the reserve, the number of moves for each
pawn is multiplied by (less than) 8 for the next turn.
This is the source of the great complexity of @|towers|.

Even on a 5x5 board, @towers can become quite complex.
In the worst case, we can keep only the master pawn on the board, 
all the other pawns being in the reserve.
Then, the number of possible moves is rougly 8^(2N-1), 
where 8 is the number of single moves,
and (2N-1) is the number of successive moves the pawn can do.
For N=5, this amounts to more than 100.000.000 possible moves, 
@emph{for a single ply!} 
(Although this is a somewhat improbable situation.)

The complexity decreases when towers are captured,
and when towers are formed.
The complexity generally increases (resp. decreases)
when pawns are exported to (resp. imported from) the reserve.

It should be noted though that moves are not often commutative in a single ply.
Breaking this symmetry also "increases" (or rather does not decrease) 
the complexity compared to situations where moves are commutative 
(which would be more the case if pawns could get out of @emph{any} tower,
not just the master: playing p1 then p2 would often be the same as p2 then p1).

;}

@; What about the depth of the games ?
@; How many moves on average in one game? 
@; In Go, this can go as far as 361, although it generally is closer 
@; It seems that the games may not be very deep?




