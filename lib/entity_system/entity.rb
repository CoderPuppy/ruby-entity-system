module EntitySystem
	class ComponentContainer
		attr_reader :next, :prev

		def initialize(val)
			@next = val
			@prev = val
		end

		def tick
			@prev = @next.clone
			self
		end
	end

	class Entity
		attr_reader :uuid
		attr_reader :components

		def initialize game
			@game = game
			@uuid = SecureRandom.uuid
			@components = Hash.new
		end

		def tick
			@components.each do |k, container|
				container.tick
			end
		end

		def partial_tick(partial)
			@components.each do |k, container|
				container.partial_tick partial
			end
		end

		def << component
			@components[component.id] = ComponentContainer.new component
			@game.processes.each do |process|
				process.add self if process.handles? self
			end
		end

		def remove id
			@components.delete id
			@game.processes.each do |process|
				process.remove self if !process.handles? self
			end
		end

		def [] id
			if id.respond_to? :id
				id = id.id
			end
			@components[id]
		end
	end
end