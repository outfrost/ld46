extends RigidBody

# Declare member variables here. Examples:
var carriedItem = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):

func _physics_process(delta):
	if Input.is_action_pressed("item_pickup"):
		var minDist = 0
		var minDistItem = null
		for item in get_node("/root/Items").get_children():
			item = item as Spatial
			var dist = item.global_transform.origin - self.global_transform.origin
			if minDistItem == null or minDist > dist:
				minDist = dist
				minDistItem = item
