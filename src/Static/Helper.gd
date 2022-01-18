extends Node
class_name Helper


########################################################
# Methods                                              #
########################################################


# Encode Image to base64.
static func encode_base64(image_path: String):
	var _SpriteFile = File.new()
	_SpriteFile.open(image_path, File.READ)
	return Marshalls.raw_to_base64(_SpriteFile.get_buffer(_SpriteFile.get_len()))


# Decode base64 string to Image.
static func decode_base64(data: String, type: String = "png") -> Image:
	var _Image = Image.new()
	var image_buffer = Marshalls.base64_to_raw(data)
	match type:
		"png":
			_Image.load_png_from_buffer(image_buffer)
		"jpg":
			_Image.load_jpg_from_buffer(image_buffer)
	return _Image


# Handle an dialog event.
static func handle_dialog_event(event: Dictionary, target: Node)->void:
	if !event.has("type"):
		return
	if !event.has("options"):
		return
	match event.type:
		"open_url":
			open_url(event.options.url)
		"open_dialog":
			open_dialog(event.options.dialog, target)


# Open a url in browser.
static func open_url(url: String)->void:
	# warning-ignore:return_value_discarded
	OS.shell_open(url)


# Open up a dialog.
static func open_dialog(dialog: String, target: Node)->void:
	target.open_dialog(dialog)
