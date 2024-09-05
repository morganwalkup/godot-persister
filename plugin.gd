@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("Persister", "res://addons/persister/persister.gd")


func _exit_tree():
	remove_autoload_singleton("Persister")
