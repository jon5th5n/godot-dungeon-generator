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


# min and max number of rooms to be generated
var min_number_of_rooms = 50
var max_number_of_rooms = 50

# the chance at which a new room will be created around the current room
var generation_chance = 20



# generate the dungeon (if generate_interesting = true you can specify how many rooms with a certain number of connections will be in your final dungeon)
func generate(generate_interesting = false, generation_seed = null):
	
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
	if connections[1] > 7 && connections[2] > 15 && connections[3] > 15 && connections[4] > 0: # <-- change the numbers here to get different kind of dungeons
		return true
