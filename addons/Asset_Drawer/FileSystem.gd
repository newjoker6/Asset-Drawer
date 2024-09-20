@tool
extends EditorPlugin

## The root scene
const ROOT: StringName = &"root"
## Padding from the bottom when popped out
const PADDING: int = 20
## Padding from the bottom when not popped out
const BOTTOM_PADDING: int = 60
## Minimum height of the dock
const MIN_HEIGHT: int = 50

## The file system
var file_dock: FileSystemDock = null

var file_split_container: SplitContainer = null
var file_tree: Tree = null
var file_container: VBoxContainer = null
var asset_drawer_shortcut: InputEventKey = InputEventKey.new()

## Toggle for when the file system is moved to bottom
var files_bottom: bool = false
var new_size: Vector2
var initial_load: bool = false
var showing: bool = false


func _enter_tree() -> void:
	# Add tool button to move shelf to editor bottom
	add_tool_menu_item("Files to Bottom", files_to_bottom)

	init_file_dock()

	await get_tree().create_timer(0.1).timeout
	files_to_bottom()

	# Prevent file tree from being shrunk on load
	await get_tree().create_timer(0.1).timeout
	file_split_container.split_offset = 175

	# Get shortcut
	asset_drawer_shortcut = preload("res://addons/Asset_Drawer/AssetDrawerShortcut.tres") as InputEventKey

func init_file_dock() -> void:
	# Get our file system
	file_dock = EditorInterface.get_file_system_dock()
	file_split_container = file_dock.get_child(3) as SplitContainer
	file_tree = file_split_container.get_child(0) as Tree
	file_container = file_split_container.get_child(1) as VBoxContainer

#region show hide filesystem
func _input(event: InputEvent) -> void:
	if not files_bottom:
		return

	if asset_drawer_shortcut.is_match(event) and event.is_pressed() and not event.is_echo():
		if showing:
			hide_bottom_panel()
		else:
			make_bottom_panel_item_visible(file_dock)

		showing = not showing
#endregion

func _exit_tree() -> void:
	remove_tool_menu_item("Files to Bottom")
	files_to_bottom()


func _process(_delta: float) -> void:
	var window := file_dock.get_window()
	new_size = window.size

	# Keeps the file system from being unusable in size
	if window.name == ROOT and not files_bottom:
		file_tree.size.y = new_size.y - PADDING
		file_container.size.y = new_size.y - PADDING
		return

	# Adjust the size of the file system based on how far up
	# the drawer has been pulled
	if window.name == ROOT and files_bottom:
		var dock_container := file_dock.get_parent() as Control
		new_size = dock_container.size
		var editorsettings := EditorInterface.get_editor_settings()
		var fontsize: int = editorsettings.get_setting("interface/editor/main_font_size")
		var editorscale := EditorInterface.get_editor_scale()

		file_tree.size.y = new_size.y - (fontsize * 2) - (BOTTOM_PADDING * editorscale)
		file_container.size.y = new_size.y - (fontsize * 2) - (BOTTOM_PADDING * editorscale)
		return

	# Keeps our systems sized when popped out
	if window.name != ROOT and not files_bottom:
		window.min_size.y = MIN_HEIGHT
		file_tree.size.y = new_size.y - PADDING
		file_container.size.y = new_size.y - PADDING

		# Centers window on first pop
		if not initial_load:
			initial_load = true
			var screenSize: Vector2 = DisplayServer.screen_get_size()
			window.position = screenSize / 2


# Moves the files between the bottom panel and the original dock
func files_to_bottom() -> void:
	if files_bottom:
		remove_control_from_bottom_panel(file_dock)
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, file_dock)
		files_bottom = false
		return

	init_file_dock()
	remove_control_from_docks(file_dock)
	add_control_to_bottom_panel(file_dock, "File System")
	files_bottom = true
