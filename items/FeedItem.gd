extends RigidBody

var scene: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	scene = get_tree().get_root().get_child(0)
	
	scene.get_node("Tree").connect("body_entered", self, "on_entered_tree")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func on_entered_tree(body):
	if body != self:
		return
	self.sleeping = true
	(get_node("CollisionShape") as CollisionShape).disabled = true
	yield(get_tree().create_timer(1.0), "timeout")
	get_parent().remove_child(self)
