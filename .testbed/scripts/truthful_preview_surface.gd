extends TextureRect

var _last_image_path := ""
var _last_image_revision := -1

func apply_preview_descriptor(descriptor: Dictionary) -> void:
	var image_path := String(descriptor.get("image_path", "")).strip_edges()
	var image_revision := int(descriptor.get("image_revision", -1))
	if image_path.is_empty():
		return
	if image_path == _last_image_path and image_revision == _last_image_revision:
		return
	if not FileAccess.file_exists(image_path):
		return
	var image := Image.new()
	var err := image.load(image_path)
	if err != OK:
		return
	texture = ImageTexture.create_from_image(image)
	_last_image_path = image_path
	_last_image_revision = image_revision
