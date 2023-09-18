@tool
extends EditorPlugin

# Vertical children to convert to Horizontal
var childVBox: int = 0
var childVSplitter: int = 3

# Separation size for the splitter you grab
var separationAmount: int = 10

# Initial spacing for the first item, filetree
var initialSplit: int = 250

# Padding from the bottom when popped out
var padding: int = 20

# The file system
var FileDock: Object

# Horizontal objects to replace the Vertical ones
var hBox: HBoxContainer = HBoxContainer.new()
var hSplitter: HSplitContainer = HSplitContainer.new()

# Used to center window the first time you pop it out
var initialLoad: bool = false

# New size used for when the windows resize
var newSize: Vector2

# Toggle for when the file system is moved to bottom
var filesBottom: bool = false

# Store vertical children for when the plugin is disabled
var fileVBox
var fileVSplitter

func _enter_tree() -> void:
	# Add tool button to move shelf to editor bottom
	add_tool_menu_item("Files to Bottom", Callable(self, "FilesToBottom"))
	
	# Get our file system
	FileDock = self.get_editor_interface().get_file_system_dock()
	
	# Replace vertical elements with horizontal ones and set parameters
	fileVBox = FileDock.get_child(childVBox)
	FileDock.get_child(childVBox).replace_by(hBox, true)
	
	hSplitter.split_offset = initialSplit
	hSplitter.add_theme_constant_override("separation", separationAmount)
	hSplitter.size = Vector2(1280, FileDock.get_window().size.y)
	
	fileVSplitter = FileDock.get_child(childVSplitter)
	FileDock.get_child(childVSplitter).replace_by(hSplitter, true)


func _exit_tree() -> void:
	remove_tool_menu_item("Files to Bottom")
	remove_control_from_bottom_panel(FileDock)
	FileDock.get_child(childVBox).replace_by(fileVBox)
	FileDock.get_child(childVSplitter).replace_by(fileVSplitter)
	if (FileDock.get_window().name != "root"):
		FileDock.get_window().emit_signal("close_requested")
	if(not filesBottom):
		remove_control_from_docks(FileDock)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, FileDock)


func _process(delta: float) -> void:
	newSize = FileDock.get_window().size
	
	# Keeps the file system from being unusable in size
	if FileDock.get_window().name == "root" && filesBottom == false:
		FileDock.get_child(3).get_child(0).size.y = newSize.y - padding
		FileDock.get_child(3).get_child(1).size.y = newSize.y - padding
		return
		
	# Adjust the size of the file system based on how far up
	# the drawer has been pulled
	if FileDock.get_window().name == "root" && filesBottom == true:
		newSize = FileDock.get_parent().size
		FileDock.get_child(3).get_child(0).size.y = newSize.y - 60
		FileDock.get_child(3).get_child(1).size.y = newSize.y - 60
		return
	
	# Keeps our systems sized when popped out
	if (FileDock.get_window().name != "root" && filesBottom == false):
		FileDock.get_window().min_size.y = 50
		FileDock.get_child(3).get_child(0).size.y = newSize.y - padding
		FileDock.get_child(3).get_child(1).size.y = newSize.y - padding
		
		# Centers window on first pop
		if initialLoad == false:
			initialLoad = true
			var screenSize: Vector2 = DisplayServer.screen_get_size()
			FileDock.get_window().position = screenSize/2
			
		return

# Moves the files between the bottom panel and the original dock
func FilesToBottom() -> void:
	if filesBottom == true:
		remove_control_from_bottom_panel(FileDock)
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, FileDock)
		filesBottom = false
		return

	FileDock = self.get_editor_interface().get_file_system_dock()
	remove_control_from_docks(FileDock)
	add_control_to_bottom_panel(FileDock, "File System")
	filesBottom = true

