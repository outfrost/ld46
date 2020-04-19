extends RigidBody

# Declare member variables here. Examples:
export var pickupRadius: float
var carryingNode: Spatial
var carriedItem: RigidBody = null

# Called when the node enters the scene tree for the first time.
func _ready():
	carryingNode = get_node("Carrying") as Spatial
	print_debug(carryingNode)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):

func _physics_process(delta):
	if Input.is_action_just_pressed("item_pickup"):
		on_item_pickup()

func on_item_pickup():
	if carriedItem != null:
		return
	var minDist = 0.0
	var minDistItem = null
	var items = get_node("/root/TestScene/Items")
	for item in items.get_children():
		item = item as RigidBody
		var dist = (item.global_transform.origin - self.global_transform.origin).length()
		if dist > pickupRadius:
			continue
		if minDistItem == null || dist < minDist:
			minDist = dist
			minDistItem = item
	if minDistItem != null:
		carriedItem = minDistItem
		items.remove_child(carriedItem)
		carryingNode.add_child(carriedItem)
		carriedItem.set_transform(Transform.IDENTITY)
		carriedItem.sleeping = true
