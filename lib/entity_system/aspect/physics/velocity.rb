module EntitySystem
	Component::Velocity = Component.new x_speed: 1, x_distance: 0, y_speed: 1, y_distance: 0
	class Process::Velocity < Process
		def handles? entity
			entity[Component::Velocity] && entity[Component::Position]
		end

		def tick
			@entities.each do |eid, entity|
				pos = entity[Component::Position].next
				vel = entity[Component::Velocity].next

				if vel.x_distance != 0
					speed = [vel.x_speed, vel.x_distance.abs].min
					pos.x += speed * vel.x_distance/vel.x_distance.abs
				end

				if vel.y_distance != 0
					speed = [vel.y_speed, vel.y_distance.abs].min
					# log :y_move, {
					# 	prev: pos.y,
					# 	next: pos.y + speed * vel.y_distance/vel.y_distance.abs,
					# 	move: speed * vel.y_distance/vel.y_distance.abs
					# }
					pos.y += speed * vel.y_distance/vel.y_distance.abs
				end
			end
		end
	end
end