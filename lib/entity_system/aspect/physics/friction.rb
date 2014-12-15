module EntitySystem
	Component::Friction = Component.new x_amt: 1, y_amt: 1
	class Process::Friction < Process
		def after;[ Process::Velocity ];end

		def handles? entity
			entity[Component::Velocity] && entity[Component::Friction]
		end

		def tick
			@entities.each do |eid, entity|
				vel = entity[Component::Velocity].next
				fri = entity[Component::Friction].next
				
				if vel.x_distance != 0
					speed = [vel.x_speed, vel.x_distance.abs].min * fri.x_amt
					vel.x_distance -= speed if vel.x_distance > 0
					vel.x_distance += speed if vel.x_distance < 0
				end

				if vel.y_distance != 0
					speed = [vel.y_speed, vel.y_distance.abs].min * fri.y_amt
					vel.y_distance -= speed if vel.y_distance > 0
					vel.y_distance += speed if vel.y_distance < 0
				end
			end
		end
	end
end