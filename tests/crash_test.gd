extends "res://tests/test_case.gd"

const GRID := Vector2i(12, 12)
const CENTER := Vector2i(6, 6)  # where a fresh dragon's head starts, heading right
const AHEAD := Vector2i.RIGHT
const SIDE := Vector2i.DOWN


## A playing session whose body is exactly `cells`, head first.
func _session_with(cells: Array[Vector2i]) -> Session:
	var session := Session.new(GRID)
	session.dragon.body.assign(cells)
	session.food = Vector2i(1, 1)  # out of the way
	session.begin()
	return session


func test_nothing_moves_until_the_first_arrow_key() -> void:
	var session := Session.new(GRID)
	var before := session.dragon.body.duplicate()
	for i in 5:
		session.tick()
	assert_eq(session.dragon.body, before)
	assert_eq(session.state, Session.State.WAITING)


func test_the_first_arrow_key_starts_the_run() -> void:
	var session := Session.new(GRID)
	session.steer(Vector2i.UP)
	assert_eq(session.state, Session.State.PLAYING)
	session.tick()
	assert_eq(session.dragon.body[0], CENTER + Vector2i.UP)


func test_hitting_a_wall_ends_the_run() -> void:
	var session := Session.new(GRID)
	session.begin()
	for i in 10:  # the wall is 5 cells away, so this is more than enough
		session.tick()
	assert_eq(session.state, Session.State.DORMANT)
	assert_eq(session.dragon.body[0], Vector2i(10, 6))  # stops on the last free cell


func test_biting_the_body_ends_the_run() -> void:
	# A hook: the head is about to enter the cell at index 3, which is not the tail.
	var session := _session_with(
		[CENTER, CENTER + SIDE, CENTER + SIDE + AHEAD, CENTER + AHEAD, CENTER + AHEAD - SIDE]
	)
	session.tick()
	assert_eq(session.state, Session.State.DORMANT)


func test_chasing_your_own_tail_is_safe() -> void:
	# A square: the head enters the very cell the tail is leaving.
	var session := _session_with([CENTER, CENTER + SIDE, CENTER + SIDE + AHEAD, CENTER + AHEAD])
	session.tick()
	assert_eq(session.state, Session.State.PLAYING)
	assert_eq(session.dragon.body[0], CENTER + AHEAD)


func test_a_growing_dragon_cannot_chase_its_tail() -> void:
	var session := _session_with([CENTER, CENTER + SIDE, CENTER + SIDE + AHEAD, CENTER + AHEAD])
	session._pending_growth = 1  # the tail will stay, so that cell is not leaving
	session.tick()
	assert_eq(session.state, Session.State.DORMANT)


func test_a_dormant_session_stops_changing() -> void:
	var session := Session.new(GRID)
	session.begin()
	for i in 10:
		session.tick()
	var frozen := session.dragon.body.duplicate()
	session.steer(Vector2i.UP)
	session.tick()
	assert_eq(session.dragon.body, frozen)
	assert_eq(session.state, Session.State.DORMANT)
