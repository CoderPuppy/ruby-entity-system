EntitySystem::Component::Velocity = EntitySystem::Component.new :x, :y
class EntitySystem::Process::Velocity < EntitySystem::Process
	def handles? entity
		entity[EntitySystem::Component::Velocity] && entity[EntitySystem::Component::Position]
	end

	def tick
		@entities.each do |entity|
			pos = entity[EntitySystem::Component::Position].next
			vel = entity[EntitySystem::Component::Velocity]

			pos.x += vel.prev.x.to_f / 2
			pos.y += vel.prev.y.to_f / 2

			pos.x += vel.next.x.to_f / 2
			pos.y += vel.next.y.to_f / 2
		end
	end
end