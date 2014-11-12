module EntitySystem
	Component::Gravity = Component.new :direction, :acceleration, :terminal_velocity
	class Process::Gravity < Process
		def before; [Component::Velocity]; end

		def handles? entity
			entity[Component::Velocity] && entity[Component::Gravity]
		end

		def tick
			@entities.each do |entity|
				vel = entity[Component::Velocity].next
				grav = entity[Component::Gravity].next
				coll = if entity[Component::Collision] && entity[Component::PhysicsCollision]
					entity[Component::Collision].next
				else
					Component::Collision[]
				end

				case grav.direction
				when :up
					vel.y += grav.acceleration if coll.touching_top.empty?
				when :down
					vel.y -= grav.acceleration if coll.touching_bottom.empty?
				when :left
					vel.x -= grav.acceleration if coll.touching_left.empty?
				when :right
					vel.x += grav.acceleration if coll.touching_right.empty?
				end

				if vel.y > grav.terminal_velocity
					vel.y = grav.terminal_velocity
				elsif vel.y < -grav.terminal_velocity
					vel.y = -grav.terminal_velocity
				end

				if vel.x > grav.terminal_velocity
					vel.x = grav.terminal_velocity
				elsif vel.x < -grav.terminal_velocity
					vel.x = -grav.terminal_velocity
				end
			end
		end
	end
end