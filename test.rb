require File.expand_path("../lib/entity_system.rb", __FILE__)

module ESTest
	include EntitySystem

	store = Store::Memory.new

	$game = Game.new store
	$game.add Process::Velocity
	$game.add Process::Friction
	# $game.add Process::Collision
	$game.add Process::PhysicsCollision
	$game.init

	$player = $game.spawn

	$player << Component::DebugName["Player"]
	$player << Component::Identity[:player]

	# Physics
	$player << Component::Area[:home]
	$player << Component::Position[0, 20]
	$player << Component::Velocity[y_speed: 20, y_distance: -100]
	$player << Component::BoundingBox[-10, -10, 20, 20]
	$player << Component::Collision[]

	$player << Component::PhysicsCollision[]
	$player << Component::Friction[]

	# Rendering
	$player << Component::Tracked[]

	$platform = $game.spawn

	$platform << Component::DebugName["Platform"]
	$platform << Component::Identity[:platform]

	# Physics
	$platform << Component::Area[:home]
	$platform << Component::Position[0, -1]
	$platform << Component::Collision[]

	$platform << Component::PhysicsCollision[]
	$platform << Component::BoundingBox[-50, 0, 100, 1]

	# ap Hash[*store.range(gte: "component:next:0", lte: "component:next:9").select do |k, v|
	# 	k.match /^component:next:\d+:/
	# end.flat_map do |k, v|
	# 	[k.gsub(/^component:next:/, ""), v]
	# end]

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
		[
			render_sized[pos.to_s.gsub(/\.0$/, ""),        4, :right],
			render_sized[render_vel[vel].gsub(/\.0$/, ""), 4, :right]
		].join " "
		# [render_sized[pos, 1, :left], render_sized[render_vel[vel], 2, :right]].join " "
	}
	render_state = ->() {
		# puts "-"*100
		pos = $player[Component::Position].next
		vel = $player[Component::Velocity].next
		box = $player[Component::BoundingBox].next
		puts render_axis_state[pos.y, vel.y_distance]
		# puts "y          = #{pos.y.ai}"
		# puts "y distance = #{vel.y_distance.ai}"
		# puts "box = #{box.offset(pos).ai}"
		# puts "platform box = #{$platform[Component::BoundingBox].next.offset($platform[Component::Position].next).ai}"
		# puts " " + [
		# 	render_axis_state[pos[0], vel[0]],
		# 	render_axis_state[pos[1], vel[1]]
		# ].join(" | ")
	}
	render_state[]
	20.times do |i|
		$game.tick
		render_state[]
	end
end