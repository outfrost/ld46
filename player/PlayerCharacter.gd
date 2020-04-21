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
var tree: Area
var rotatingStuff: Spatial
var cameraOrbit: Spatial
var camera: Camera
var debugLabel: Label
var animationPlayer: AnimationPlayer
var carryingNode: Spatial
var carriedItem: RigidBody = null
var jumpState = JumpState.IDLE
var lastVelocity: Vector3 = Vector3.ZERO
var gameOver = false

var cameraDefTransform: Transform
var cameraRotatedTransform: Transform
var cameraDefFov: float

# Called when the node enters the scene tree for the first time.
func _ready():
	scene = get_tree().get_root().get_child(0)
	tree = scene.get_node("Tree")
	rotatingStuff = self.get_node("RotatingStuff") as Spatial
	cameraOrbit = self.get_node("CameraOrbit") as Spatial
	camera = cameraOrbit.get_node("CameraPivot/Camera") as Camera
	debugLabel = camera.get_node("DebugLabel") as Label
	animationPlayer = rotatingStuff.get_node("Player/AnimationPlayer")
	carryingNode = rotatingStuff.get_node("Carrying") as Spatial
	
	tree.connect("body_entered", self, "on_body_entered_tree")
	tree.connect("died", self, "on_tree_died")
	
	cameraDefTransform = camera.transform
	cameraRotatedTransform = cameraDefTransform.rotated(Vector3.RIGHT, deg2rad(40.0))
	cameraDefFov = camera.fov

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):

func _physics_process(delta):
	if gameOver:
		return
	var accel = (self.linear_velocity - lastVelocity) / delta
	if accel.y > -(9.7 * self.gravity_scale):
		self.jumpState = JumpState.IDLE
	else:
		self.jumpState = JumpState.AIRBORNE
	lastVelocity = self.linear_velocity
	var planarSpeed = vector_util.discard_y(self.linear_velocity).length()
	if planarSpeed > 2.0:
		animationPlayer.play("Armature|Running Loop", -1, 1.5)
	else:
		animationPlayer.play("Armature|Action")
	
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
	self.add_central_force(movementDirection * movementForce)
	var planarLinearSpeed = vector_util.discard_y(self.linear_velocity).length()
	if planarLinearSpeed > maxPlanarSpeed:
		self.linear_velocity.x /= planarLinearSpeed / maxPlanarSpeed
		self.linear_velocity.z /= planarLinearSpeed / maxPlanarSpeed
	
	if jumpState == JumpState.IDLE && Input.is_action_just_pressed("movement_jump"):
		self.set_axis_velocity(Vector3.UP * jumpSpeed)
		#jumpState = JumpState.AIRBORNE
	
	var directionToTree = vector_util.discard_y(tree.global_transform.origin - self.global_transform.origin).normalized()
	var directionForward = vector_util.discard_y(- self.global_transform.basis.z).normalized()
	cameraOrbit.transform = Transform.IDENTITY.rotated(
		Vector3.UP,
		directionForward.angle_to(directionToTree) * (- sign(directionToTree.x)))
	
	var distanceToTree = vector_util.discard_y(tree.global_transform.origin - self.global_transform.origin).length()
	var t = smoothstep(0.0, 1.0, clamp(1 - (distanceToTree / 75.0), 0.0, 1.0))
	t *= t # squared
	#debugLabel.text = String(t)
	camera.transform = cameraDefTransform.interpolate_with(cameraRotatedTransform, t)
	camera.fov = lerp(cameraDefFov, cameraDefFov + 15, t)
	
	#var modelDirection = vector_util.discard_y(- rotatingStuff.global_transform.basis.z).normalized()
	rotatingStuff.rotate_y(directionForward.angle_to(movementDirection) * (- sign(movementDirection.x)))
	rotatingStuff.transform = Transform.IDENTITY.rotated(
		Vector3.UP,
		directionForward.angle_to(movementDirection) * (- sign(movementDirection.x)))

func on_body_entered_tree(body):
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

func on_tree_died():
	gameOver = true

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
