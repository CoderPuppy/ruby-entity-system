-- Player
Area :place

Position {
	x: 0
	y: 0
}

Size {
	width: 1
	height: 2
}

Velocity {
	x: 0
	y: 0
}

Facing :down

Collison

-- Travel Pad
Area :place

Position {
	x: 0
	y: 0
}

Size {
	width: 1
	height: 1
}

Collison

Teleport {
	area: :other_place
	x: 0
	y: 0
}