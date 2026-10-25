class_name PlayerPickupBox
extends Area2D


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is not ItemPickup:
		return # some other shit for some reason. skip
	
	var pickup :ItemPickup = area.get_parent()
	pickup.getPickedUp() # into the poop state
