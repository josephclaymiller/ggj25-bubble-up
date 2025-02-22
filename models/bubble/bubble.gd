extends "res://models/collidable/collidable.gd"

# Constants
var _collision_merge_accel_threshold: int = 1
var _collision_split_accel_threshold: int = 4
var _split_mass_vanish_threshold: float   = 0.5
var _collision_cooldown_millis: int       = 100

# var _max_scale_factor: int				= 10

# Scale factor for the sprite and collision area
@export var sprite_scale_factor: float = 0.8
@export var collision_scale_factor: float = 0.5

# Load the bubble textures
@onready var bubble_sprites: Array[Variant] = [
											  preload("res://assets/bubble_test.png"),
											  #	preload("res://assets/bubble1.png"),
											  #	preload("res://assets/bubble2.png"),
											  #	preload("res://assets/bubble3.png"),
											  #	preload("res://assets/bubble4.png")
											  ]

# Export the vanish particle effect resource so you can set it in the inspector
@export var vanish_particle_effect: PackedScene

# Reference to the Sprite node
@onready var sprite: Sprite2D = $Sprite2D
# Reference to the Collision node
@onready var collision: CollisionShape2D = $CollisionShape2D
# Reference to the vanish particle emitter node
@onready var vanish_particle_emitter: CPUParticles2D = $CPUParticles2D


# Called when the bubble is instantiated
func _init():
	super._init()
	
	
# Called every frame to check if the bubble has risen to the surface
func _process(_delta) -> void:
	if global_position.y < 0:
		# TODO score the bubble by mass
		vanish()


# Called when the scene is added to the tree
# Load the sprite and connect the signal
func _ready():
	super._ready()
	add_to_group(Global.GROUP_BUBBLES)
	connect("body_entered", Callable(self, "_on_body_entered"))
	update_mass(mass)


# Called when another body enters the collision area
func _on_body_entered(other):
	if other is RigidBody2D:
		if other.is_in_group(Global.GROUP_BUBBLES):
			_on_collision_with_bubble(other)
		elif other.is_in_group(Global.GROUP_MOVABLES):
			_on_collision_with_movable(other)
		else:
			print("Unknown collision: " + name + " → " + other.name)


# Function to handle collision with another bubble
func _on_collision_with_bubble(other) -> void:
	if min(age(), other.age()) < _collision_cooldown_millis:
		return
	var a: Vector2 = acceleration()
	var b: float   = a.length()
	if abs(b) > _collision_merge_accel_threshold:
		merge_into(other)


# Function to handle collision with a movable object
func _on_collision_with_movable(other) -> void:
	if min(age(), other.age()) < _collision_cooldown_millis:
		return
	var effective_force = other.bubble_split_factor * abs(acceleration().length())
	if  effective_force > _collision_split_accel_threshold:
		split()


# Function to merge two bubbles
func merge_into(other) -> void:
	# If the other bubble is smaller or faster, call the function to merge that into this instead
	if mass > other.mass or (mass == other.mass and linear_velocity.length() < other.linear_velocity.length()):
		other.merge_into(self)
		return

	# Lock the other bubble to prevent further collisions
	if is_freeze_enabled() or other.is_freeze_enabled():
		return
	else:
		set_deferred("freeze", true)

	# Update the other bubble's mass
	other.update_mass(mass + other.mass)

	# Destroy this bubble
	queue_free()


# Function to split a bubble: remove the current bubble and spawn two new bubbles with half the mass. Position the two
# new bubbles on opposite sides of the center of the original bubble, halfway between the center and the outside. New
# bubbles inherit the acceleration of the original bubble
func split() -> void:
	# Lock the other bubble to prevent further collisions
	if is_freeze_enabled():
		return
	else:
		set_deferred("freeze", true)

	# Calculate the new mass for the two bubbles
	var new_mass: float = mass / 2

	# If mass is below threshold, this is a vanish action, not split
	if new_mass < _split_mass_vanish_threshold:
		vanish()
		return

	# Calculate the new position for the two bubbles
	var r: float   = sprite.get_rect().size.length() / 4
	var a: float   = linear_velocity.angle()
	var v: Vector2 = Vector2(cos(a), sin(a)) * r

	# Create the new bubble 1
	var b1 = preload("res://models/bubble/bubble.tscn").instantiate()
	b1.position = position + v
	b1.mass = new_mass
	get_parent().add_child(b1)

	# Create the new bubble 2
	var b2 = preload("res://models/bubble/bubble.tscn").instantiate()
	b2.position = position - v
	b2.mass = new_mass
	get_parent().add_child(b2)

	# Destroy this bubble
	queue_free()


# Function to destroy the bubble and spawn the vanish particle effect
func vanish():
	# Check if a particle effect is assigned
	if vanish_particle_effect:
		# Instance the particle effect
		var particles = vanish_particle_effect.instance()
		# Add it as a child of the bubble's parent so it's positioned correctly
		get_parent().add_child(particles)
		# Set the position of the particles to the bubble's position
		particles.global_position = global_position

		# Optional: Start the particle effect
		if particles.has_method("restart"):
			particles.restart()

	# Activate the particle emitter
	vanish_particle_emitter.emitting = true

	# Hide the sprite, disable the collision shape, wait 1 second, then queue free
	sprite.hide()
	collision.disabled = true
	await get_tree().create_timer(1).timeout
	queue_free()


# Function to update the scale of the bubble based on its mass
func update_mass(new_mass: float):
	mass = new_mass
	var scale_factor: float = pow(mass, 0.333)
	sprite.scale = Vector2(scale_factor, scale_factor) * sprite_scale_factor
	collision.scale = Vector2(scale_factor, scale_factor) * collision_scale_factor
	sprite.texture = bubble_sprites[0]
	# TODO sprite.texture = bubble_sprites[clamp(int(bubble_sprites.size() * scale_factor / _max_scale_factor), 0, bubble_sprites.size() - 1)]
