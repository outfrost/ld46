extends RigidBody

const vector_util = preload("res://util/vector_util.gd")

enum JumpState {
	IDLE,
	AIRBORNE,
}

# Declare member variables here.
export var pickupRadius: float
export var movementForce: float
export var maxPlanarSpeed: float
export var jumpSpeed: float

var scene: Node
var camera: Camera
var debugLabel: Label
var carryingNode: Spatial
var carriedItem: RigidBody = null
var jumpState = JumpState.IDLE

# Called when the node enters the scene tree for the first time.
func _ready():
	scene = get_tree().get_root().get_child(0)
	camera = self.get_node("Camera") as Camera
	debugLabel = camera.get_node("DebugLabel") as Label
	carryingNode = self.get_node("Carrying") as Spatial
	
	scene.get_node("Tree").connect("body_entered", self, "on_entered_tree")
	self.connect("body_entered", self, "on_body_entered")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):

func _physics_process(delta):
	process_movement_inputs()
	if Input.is_action_just_pressed("item_pickup"):
		on_item_pickup()

func process_movement_inputs():
	var forward = vector_util.discard_y(- camera.global_transform.basis.z).normalized()
	var right = vector_util.discard_y(camera.global_transform.basis.x).normalized()
	var movementDirection = (
		right * (Input.get_action_strength("movement_right") - Input.get_action_strength("movement_left"))
		+ forward * (Input.get_action_strength("movement_forward") - Input.get_action_strength("movement_backward"))
	).normalized()
	debugLabel.text = String(movementDirection)
	self.add_central_force(movementDirection * movementForce)
	var planarLinearSpeed = vector_util.discard_y(self.linear_velocity).length()
	if planarLinearSpeed > maxPlanarSpeed:
		self.linear_velocity.x /= planarLinearSpeed / maxPlanarSpeed
		self.linear_velocity.z /= planarLinearSpeed / maxPlanarSpeed
	
	if jumpState == JumpState.IDLE && Input.is_action_just_pressed("movement_jump"):
		self.set_axis_velocity(Vector3.UP * jumpSpeed)
		jumpState = JumpState.AIRBORNE

func _on_Bullet_body_entered():
	

func on_body_entered(body):
	print_debug("FUCK")
	if body.name == "Terrain":
		print_debug("WOO")

func on_hit_terrain(body):
	if body != self:
		return
	print_debug("Hit terrain")
	jumpState = JumpState.IDLE

func on_entered_tree(body):
	if body != self:
		return
	on_item_drop()

func on_item_pickup():
	if carriedItem:
		drop_item()
	else:
		pickup_item()

func on_item_drop():
	if carriedItem == null:
		return
	drop_item()

func pickup_item():
	var minDist = 0.0
	var minDistItem = null
	var items = scene.get_node("Items")
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
		(carriedItem.get_node("CollisionShape") as CollisionShape).disabled = true

func drop_item():
	carryingNode.remove_child(carriedItem)
	scene.get_node("Items").add_child(carriedItem)
	carriedItem.transform *= carryingNode.transform
	carriedItem.transform *= self.transform
	carriedItem.linear_velocity = self.linear_velocity + self.linear_velocity.normalized() * 3.0
	carriedItem.sleeping = false
	(carriedItem.get_node("CollisionShape") as CollisionShape).disabled = false
	carriedItem = null
