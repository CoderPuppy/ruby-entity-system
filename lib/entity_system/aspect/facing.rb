module EntitySystem
	Component::Facing = Component.new dir: :down
	class Process::Facing < Process
		def after;[ Process::Velocity ];end
		def before;[ Process::PhysicsCollision ];end

		def handles? entity
			entity[Component::Facing] && entity[Component::Position]
		end

		def tick
			@entities.each do |eid, entity|
				prev_pos = entity[Component::Position].prev
				next_pos = entity[Component::Position].next

				if next_pos != prev_pos
					entity[Component::Facing].next.dir = case true
					when next_pos.y > prev_pos.y
						:up
					when next_pos.y < prev_pos.y
						:down
					when next_pos.x > prev_pos.x
						:right
					when next_pos.x < prev_pos.x
						:left
					end
				end
			end
		end
	end
end