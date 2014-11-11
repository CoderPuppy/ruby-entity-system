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

				case grav.direction
				when :up
					vel.y += grav.acceleration
				when :down
					vel.y -= grav.acceleration
				when :left
					vel.x -= grav.acceleration
				when :right
					vel.x += grav.acceleration
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