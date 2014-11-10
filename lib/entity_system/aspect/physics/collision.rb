EntitySystem::Component::Collision = EntitySystem::Component.new :colliding
class EntitySystem::Process::Collision < EntitySystem::Process
	def handles? entity
		entity[EntitySystem::Component::BoundingBox] && entity[EntitySystem::Component::Collision]
	end
end