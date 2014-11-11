module EntitySystem
	class ComponentContainer
		attr_reader :game
		attr_reader :eid
		attr_reader :cla, :cid

		def initialize(game, eid, cla, cid)
			@game = game
			@eid = eid
			@cla = cla
			@cid = cid
		end

		def prev
			Component::Synthesized.new(@game, @cla, @cid, :prev)
		end

		def next
			Component::Synthesized.new(@game, @cla, @cid, :next)
		end
	end

	class Entity
		attr_reader :game
		attr_reader :id

		def initialize game, id
			@game = game
			@id = id
		end

		def partial_tick(partial)
			@components.each do |k, container|
				container.partial_tick partial
			end
		end

		def << component
			cid = @game.store.add_component @id, component
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

		def [] cla, id = nil
			if cla.singular
				id ||= "main"
			end
			if id == nil
				@game.store.components(@id).map do |id|
					cid = @game.store.component @id, cla.id, id
					ComponentContainer.new(@game, @id, cla, id, cid)
				end
			else
				cid = @game.store.component @id, cla.id, id
				if cid
					ComponentContainer.new(@game, @id, cla, cid)
				end
			end
		end

		def inspect
			"#<Entity:#{@id}>"
		end
	end
end