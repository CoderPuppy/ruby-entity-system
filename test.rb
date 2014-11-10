require File.expand_path("../lib/entity_system.rb", __FILE__)

module ESTest
	include EntitySystem

	store = Store::PureMem.new

	$game = Game.new store
	$game.add Process::Velocity
	$game.add Process::Friction
	$game.add Process::Gravity
	$game.add Process::Collision
	$game.init

	$player = $game.spawn

	$player << Component::DebugName["Player"]
	$player << Component::Identity[:player]

	# Physics
	$player << Component::Area[:home]
	$player << Component::Position[0, 0]
	$player << Component::Velocity[0, 0]
	$player << Component::BoundingBox[Rect[0, 0]]

	$player << Component::Collision[]
	$player << Component::Friction[1]
	$player << Component::Gravity[:down, 1, 2]

	# Rendering
	$player << Component::Tracked[]

	render_sized = ->(text, size, side) {
		text = text.to_s
		if text.length < size
			case side
			when :left
				text + " " * (size - text.length)
			when :right
				" " * (size - text.length) + text
			end
		else
			text
		end
	}
	render_vel = ->(vel) {
		if vel > 0
			"+#{vel}"
		elsif vel < 0
			"#{vel}"
		else
			" #{vel}"
		end
	}
	render_axis_state = ->(pos, vel) {
		[render_sized[pos.to_s.gsub(/\.0$/, ""), 4, :left], render_sized[render_vel[vel].gsub(/\.0$/, ""), 4, :left]].join " "
		# [render_sized[pos, 1, :left], render_sized[render_vel[vel], 2, :right]].join " "
	}
	render_state = ->() {
		pos = $player[Component::Position].next
		vel = $player[Component::Velocity].next
		puts " " + [
			render_axis_state[pos[0], vel[0]],
			render_axis_state[pos[1], vel[1]]
		].join(" | ")
	}
	render_state[]
	200.times do |i|
		if i == 1
			vel = $player[Component::Velocity].next
			vel.x += 2
			vel.y += 1
		end
		$game.tick
		render_state[]
	end
end