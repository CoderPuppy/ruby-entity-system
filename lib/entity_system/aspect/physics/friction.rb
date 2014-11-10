EntitySystem::Component::Friction = EntitySystem::Component.new :amt
class EntitySystem::Process::Friction < EntitySystem::Process
	def before; [EntitySystem::Process::Velocity]; end

	def handles? entity
		entity[EntitySystem::Component::Velocity] && entity[EntitySystem::Component::Friction]
	end

	def tick
		@entities.each do |entity|
			vel = entity[EntitySystem::Component::Velocity].next
			fri = entity[EntitySystem::Component::Friction].next

			if vel.x > 0
				vel.x -= fri.amt.to_f
				if vel.x < 0
					vel.x = 0
				end
			elsif vel.x < 0
				vel.x += fri.amt.to_f
				if vel.x > 0
					vel.x = 0
				end
			end

			if vel.y > 0
				vel.y -= fri.amt.to_f
				if vel.y < 0
					vel.y = 0
				end
			elsif vel.y < 0
				vel.y += fri.amt.to_f
				if vel.y > 0
					vel.y = 0
				end
			end
		end
	end
end