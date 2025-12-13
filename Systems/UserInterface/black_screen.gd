extends ColorRect

@export var fade_time := 0.35
var tween: Tween

func fade_in() -> void:
	# fade from black to clear
	modulate.a = 1.0
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)

func fade_out() -> void:
	# fade from clear to black
	modulate.a = 0.0
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)
	
func fade_out_wait():
	fade_out()
	return await get_tree().create_timer(fade_time).timeout

func fade_in_wait():
	fade_in()
	return await get_tree().create_timer(fade_time).timeout
