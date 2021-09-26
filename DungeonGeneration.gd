extends Node

var rng = RandomNumberGenerator.new()


# an array with all the directions for picking one randomly
const directions = [ Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT ]
# this is the template for how a the room dictionarys are structured (somewhat used like a class)
const room_template = {
	"position" : Vector2(0, 0),
	"connected_rooms" : { Vector2.UP : null, Vector2.RIGHT : null, Vector2.DOWN : null, Vector2.LEFT : null },
	"number_of_connections" : 0
}


var min_rooms = 50
var max_rooms = 50
var gen_chance = 20



# generate the dungeon (if generate_interesting = true you can specify how many rooms with a certain number of connections will be in your final dungeon)
func generate_dungeon(generate_interesting = false, min_number_of_rooms = min_rooms, max_number_of_rooms = max_rooms, generation_chance = gen_chance, generation_seed = null):
	
	var interesting = false
	var dungeon
	
	# this will generate dungeons until one lays within the specifications
	while !interesting:
		#== actual generation ======================================================
		
		if generation_seed == null: rng.randomize()
		else: rng.seed = generation_seed
		
		var original_size = rng.randi_range(min_number_of_rooms, max_number_of_rooms)
		var size = original_size
		
		dungeon = {}
		
		dungeon[Vector2(0, 0)] = room_template.duplicate(true)
		size -= 1
		
		while size > 0:
			for current_room_position in dungeon.keys():
				
				if rng.randi_range(0, 100) < generation_chance:
					
					var direction = directions[rng.randi_range(0, 3)]
					# the position for the new room resulting from the position of the current room and the direction
					var new_room_position = current_room_position + direction
					
					# if there is not already a room at this position
					if !dungeon.has(new_room_position):
						
						# create new room and add the current room to its connected rooms
						var new_room = room_template.duplicate(true)
						new_room.position = new_room_position
						
						# add the new room to the dungeon
						dungeon[new_room_position] = new_room
						
						size -= 1
					
					# if the room hast no connection to the other room in the direction
					if dungeon[current_room_position].connected_rooms[direction] == null :
						# add the room at the position to the connections of the current room
						connect_rooms(dungeon[current_room_position], dungeon[new_room_position], direction)
		
		#===========================================================================
		
		# check if the current dungeon is interesting
		interesting = is_interesting(dungeon)
		# if generate_interesting = false set interesting true so the first dungeon generated will be returned
		if !generate_interesting: interesting = true
	
	return dungeon



# generates a dungeon composed of multiple single dungeons
func generate_multi_dungeon(multi_size, generate_interesting = false, min_number_of_rooms = min_rooms, max_number_of_rooms = max_rooms, generation_chance = gen_chance):
	var dungeon1 = generate_dungeon(generate_interesting, min_number_of_rooms, max_number_of_rooms, generation_chance)
	
	for i in range(multi_size):
		var dungeon2 = null
		while dungeon2 == null:
			dungeon2 = generate_dungeon(generate_interesting, min_number_of_rooms, max_number_of_rooms, generation_chance)
			dungeon2 = find_adding_position(dungeon1, dungeon2)
		dungeon1 = add_dungeons(dungeon1, dungeon2)
	
	return dungeon1





# connects two rooms together (direction is relative to room1)
func connect_rooms(room1, room2, direction):
	room1.connected_rooms[direction] = room2.position
	room2.connected_rooms[-direction] = room1.position
	
	room1.number_of_connections += 1
	room2.number_of_connections += 1

# checks if a dungeon has a certain number of rooms with one, two, three or four connections
func is_interesting(dungeon):
	# this array will hold how many rooms with one [1], two [2], three [3] or four [4] connections there are
	var connections = [null, 0, 0, 0, 0]
	
	# count how many rooms with a certain number of connections are in the dungeon
	for i in dungeon.keys():
		connections[dungeon[i].number_of_connections] += 1
	
	# check if it passes the specifications
	#if connections[1] > 7 && connections[2] > 15 && connections[3] > 15 && connections[4] > 0: # <-- change the numbers here to get different kind of dungeons
	if connections[1] < 8 && connections[2] > 0 && connections[3] > 0 && connections[4] > 0:
		return true



# gets the most top left rooms and the most bottom right rooms coordinate
func get_dungeon_corners(dungeon):
	var lowest
	var highest
	
	for key in dungeon.keys():
		if lowest == null || highest == null:
			lowest = key
			highest = key
			
		else:
			if key.x < lowest.x: lowest.x = key.x
			if key.y < lowest.y: lowest.y = key.y
			if key.x > highest.x: highest.x = key.x
			if key.y > highest.y: highest.y = key.y
	
	var corners = {
		"top_left" : lowest,
		"bottom_right" : highest
	}
	return corners

# gets the width and height of the dungeon
func get_dungeon_dimensions(dungeon):
	var corners = get_dungeon_corners(dungeon)
	
	var size = (corners.bottom_right - corners.top_left) + Vector2(1, 1)
	return size


# offsets the position of a dungeon
func change_dungeon_position(dungeon, change : Vector2):
	var changed_dungeon = {}
	
	for key in dungeon.keys():
		var changed_room = dungeon[key]
		changed_room.position = key + change
		changed_dungeon[key + change] = changed_room
	
	return changed_dungeon

# trys to find a offset of the second dungeon on which the two dungeons can be merged with the min and max requirements of overlapping rooms being met
func find_adding_position(dungeon1, dungeon2):
	
	var min_overlapping = 1
	var max_overlapping = 2
	
	var dungeon1_corners = get_dungeon_corners(dungeon1)
	var dungeon2_corners = get_dungeon_corners(dungeon2)
	
	var untried_positions = []
	for i in range(dungeon1_corners.top_left.x - dungeon2_corners.bottom_right.x, dungeon1_corners.bottom_right.x - dungeon2_corners.top_left.x):
		for j in range(dungeon1_corners.top_left.y - dungeon2_corners.bottom_right.y, dungeon1_corners.bottom_right.y - dungeon2_corners.top_left.y):
			untried_positions.append(Vector2(i, j))
	
	while untried_positions.size() > 0:
		
		var rand = rng.randi_range(0, untried_positions.size() - 1)
		
		var tmp_dungeon = change_dungeon_position(dungeon2, untried_positions[rand])
		
		var overlapping_rooms = 0
		for tmpd_key in tmp_dungeon.keys():
			for d1_key in dungeon1.keys():
				
				if tmpd_key == d1_key:
					overlapping_rooms += 1
		
		if overlapping_rooms >= min_overlapping && overlapping_rooms < max_overlapping:
			return tmp_dungeon
		untried_positions.remove(rand)
	
	return null

# adds two dungeons together
func add_dungeons(dungeon1, dungeon2):
	var dungeon = dungeon1.duplicate(true)
	
	for key in dungeon2:
		if dungeon.has(key):
			for room_key in dungeon2[key].connected_rooms.keys():
				if dungeon2[key].connected_rooms[room_key] != null && dungeon[key].connected_rooms[room_key] == null:
					dungeon[key].connected_rooms[room_key] = dungeon2[key].connected_rooms[room_key]
					dungeon[key].number_of_connections += 1
		else:
			dungeon[key] = dungeon2[key]
	
	return dungeon




