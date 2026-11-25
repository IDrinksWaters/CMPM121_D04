## One run at the game: the board and the dragon on it, from the first tick until the
## run ends. Rules that involve more than the dragon (food, score, what the dragon can
## run into) belong here, so Dragon stays about movement and app/ only draws.
class_name Session
extends RefCounted

const GROWTH_PER_FOOD := 3  # cells the body gains per bite, we make it 3 for now
const NO_FOOD := Vector2i(-1, -1)  # off the board: "there is no food right now"

var board: Board
var dragon: Dragon
var food := NO_FOOD
var score := 0  # how many pieces of food have been eaten

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


## One step of the rules. TODO for D4: collisions with the dragon's own body and with
## solid tiles (board.is_solid). They need the dragon and something else, which is why
## they go here rather than in Dragon.tick.
func tick() -> void:
	var old_tail: Vector2i = dragon.body.back()
	dragon.tick()
	if dragon.body[0] == food:
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