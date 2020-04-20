extends Node

export var spawnInterval: float
export var thingsToSpawn: Array

onready var scene: Node = get_tree().get_root().get_child(0)
onready var items: Node = scene.get_node("Items")
var spawnedItems = {}
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	spawn_loop()
	check_loop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn_loop():
	while true:
		var spawnPoints = self.get_children()
		var point: Spatial = spawnPoints[rng.randi_range(0, spawnPoints.size() - 1)]
		for i in range(0, (spawnPoints.size())):
			if spawnedItems.has(point):
				point = spawnPoints[rng.randi_range(0, spawnPoints.size() - 1)]
			else:
				var thing: Spatial = (thingsToSpawn[rng.randi_range(0, thingsToSpawn.size() - 1)] as PackedScene).instance()
				thing.transform = point.transform
				items.add_child(thing)
				spawnedItems[point] = thing
		yield(get_tree().create_timer(spawnInterval), "timeout")

func check_loop():
	while true:
		for key in spawnedItems.keys():
			if (spawnedItems[key] as Spatial).get_parent() == null:
				spawnedItems.erase(key)
		yield(get_tree().create_timer(1.0), "timeout")
