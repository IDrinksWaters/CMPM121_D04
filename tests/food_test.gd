extends "res://tests/test_case.gd"

const GRID := Vector2i(12, 12)


## The cell the head enters on the first tick, found by running a twin Session.
func _first_cell_ahead() -> Vector2i:
	var probe := Session.new(GRID)
	probe.begin()
	probe.tick()
	return probe.dragon.body[0]


func test_eating_grows_the_body_by_the_chosen_amount() -> void:
	var session := Session.new(GRID)
	var before := session.dragon.body.size()
	session.begin()
	session.food = _first_cell_ahead()
	for i in Session.GROWTH_PER_FOOD:  # growth is spread over the next few ticks
		session.tick()
	assert_eq(session.dragon.body.size(), before + Session.GROWTH_PER_FOOD)


func test_new_food_never_appears_on_the_body() -> void:
	var session := Session.new(GRID)
	# Cover every free cell with the body except one: food has only one legal place.
	var spare := Session.NO_FOOD
	var cells: Array[Vector2i] = []
	for y in GRID.y:
		for x in GRID.x:
			var cell := Vector2i(x, y)
			if session.board.is_solid(cell):
				continue
			if spare == Session.NO_FOOD:
				spare = cell
			else:
				cells.append(cell)
	session.dragon.body.assign(cells)
	session.place_food()
	assert_eq(session.food, spare)
	assert_true(not session.dragon.body.has(session.food))


func test_food_is_never_on_a_solid_tile() -> void:
	var session := Session.new(GRID, 7)
	for i in 50:
		session.place_food()
		assert_true(not session.board.is_solid(session.food))


func test_score_counts_what_was_eaten() -> void:
	var session := Session.new(GRID)
	assert_eq(session.score, 0)
	session.begin()
	session.food = _first_cell_ahead()
	session.tick()
	assert_eq(session.score, 1)


func test_new_food_appears_after_a_bite() -> void:
	var session := Session.new(GRID)
	session.begin()
	session.food = _first_cell_ahead()
	session.tick()
	assert_true(session.food != Session.NO_FOOD)
	assert_true(not session.dragon.body.has(session.food))


func test_same_seed_gives_same_food() -> void:
	assert_eq(Session.new(GRID, 42).food, Session.new(GRID, 42).food)
