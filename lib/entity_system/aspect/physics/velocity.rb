module EntitySystem
	Component::Velocity = Component.new :x, :y
	class Process::Velocity < Process
		def handles? entity
			entity[Component::Velocity] && entity[Component::Position]
		end

		def tick
			@entities.each do |entity|
				pos = entity[Component::Position].next
				vel = entity[Component::Velocity]

				pos.x += vel.prev.x.to_f / 2
				pos.y += vel.prev.y.to_f / 2

				pos.x += vel.next.x.to_f / 2
				pos.y += vel.next.y.to_f / 2
			end
		end
	end
end