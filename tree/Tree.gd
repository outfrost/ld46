extends Area

var FeedItem = preload("res://items/FeedItem.gd")

signal died;

export var leafMaterial: SpatialMaterial
export var hpDecayRate: float

onready var scene: Node = get_tree().get_root().get_child(0)
onready var gameOverOverlay: Panel = scene.find_node("Camera").get_node("GameOverOverlay")
onready var light: OmniLight = self.get_node("OmniLight")
onready var defLightEnergy = light.light_energy
onready var defEmissionEnergy = leafMaterial.emission_energy
var hp = 100.0
var died = false

func _ready():
	(gameOverOverlay.get_node("Button") as Button).connect("pressed", self, "on_restart_pressed")
	self.connect("body_entered", self, "on_body_entered")

func _process(delta):
	if died:
		return
	hp -= hpDecayRate * delta
	hp = clamp(hp, 0.0, 100.0)
	light.light_energy = lerp(0.0, defLightEnergy, hp / 100.0)
	leafMaterial.emission_energy = lerp(0.0, defEmissionEnergy, hp / 100.0)
	if (abs(hp) < 0.1):
		emit_signal("died")
		leafMaterial.emission_energy = defEmissionEnergy
		gameOverOverlay.visible = true

func on_restart_pressed():
	get_tree().reload_current_scene()

func on_body_entered(body):
	if body is FeedItem:
		hp += 25.0
