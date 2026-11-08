class_name GiftCatalog
extends Resource
## The pool of possible gifts that wish lists are picked from.
## Edit the list by double-clicking gift_catalog.tres in Godot.

@export var gift_names: Array[String] = []


## Returns `count` different gifts in random order.
## If the catalog has fewer gifts than asked for, returns all of them.
func pick_random_gifts(count: int) -> Array[String]:
	if count > gift_names.size():
		push_warning("Wish list wants %d gifts but the catalog only has %d." % [count, gift_names.size()])
	var shuffled: Array[String] = gift_names.duplicate()
	shuffled.shuffle()
	var picked: Array[String] = shuffled.slice(0, mini(count, shuffled.size()))
	return picked
