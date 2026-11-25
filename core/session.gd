## One run at the game: the board and the dragon on it, from the first tick until the
## run ends. Rules that involve more than the dragon (food, score, what the dragon can
## run into) belong here, so Dragon stays about movement and app/ only draws.
class_name Session
extends RefCounted

## WAITING: nothing moves until the first arrow key. PLAYING: ticks move the dragon.
## DORMANT: the run is over; the dragon sleeps to save its energy.
enum State { WAITING, PLAYING, DORMANT }

const GROWTH_PER_FOOD := 3  # cells the body gains per bite
const NO_FOOD := Vector2i(-1, -1)  # off the board: "there is no food right now"

var board: Board
var dragon: Dragon
var state := State.WAITING
var food := NO_FOOD
var score := 0  # how many glowberries have been eaten

var _grid_size: Vector2i
var _rng := RandomNumberGenerator.new()
var _pending_growth := 0  # growth still owed from bites already taken


## The seed makes the "random" food placement repeatable, so tests can predict it.
func _init(grid_size: Vector2i, seed_value := 1) -> void:
	_grid_size = grid_size
	board = Board.bordered(grid_size)
	dragon = Dragon.new(grid_size)
	_rng.seed = seed_value
	place_food()


## Start the run. Only the first call does anything.
func begin() -> void:
	if state == State.WAITING:
		state = State.PLAYING


## A player's arrow key: queue the turn, and the first one also starts the run.
## Once the dragon is dormant, keys do nothing.
func steer(direction: Vector2i) -> void:
	if state == State.DORMANT:
		return
	dragon.turn(direction)
	begin()


## One step of the rules. The run ends when the head enters a solid tile or the body.
## The cell the tail is leaving counts as free, unless the dragon is growing this tick
## (then the tail stays put, so entering it is a bite).
func tick() -> void:
	if state != State.PLAYING:
		return
	var before: Array[Vector2i] = dragon.body.duplicate()
	var old_tail: Vector2i = before.back()
	dragon.tick()
	var head: Vector2i = dragon.body[0]
	# Dragon.tick has already dropped the tail, so the body checked here is the new one.
	var bit_body: bool = dragon.body.slice(1).has(head)
	var bit_staying_tail := _pending_growth > 0 and head == old_tail
	if board.is_solid(head) or bit_body or bit_staying_tail:
		dragon.body.assign(before)  # the dragon stops on its last safe cell
		state = State.DORMANT
		return
	if head == food:
		score += 1
		_pending_growth += GROWTH_PER_FOOD
		food = NO_FOOD
	if _pending_growth > 0:
		# Growing means the tail stays where it was this step instead of following.
		dragon.body.append(old_tail)
		_pending_growth -= 1
	if food == NO_FOOD:
		place_food()


## Put the food on a random free cell: not solid, not under the dragon.
## Public so tests can call it directly. If the board is full there is no free cell.
func place_food() -> void:
	var free: Array[Vector2i] = []
	for y in _grid_size.y:
		for x in _grid_size.x:
			var cell := Vector2i(x, y)
			if not board.is_solid(cell) and not dragon.body.has(cell):
				free.append(cell)
	food = NO_FOOD if free.is_empty() else free[_rng.randi_range(0, free.size() - 1)]
