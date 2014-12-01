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
			Component.synthesize(@game, @cla, @cid, :prev)
		end

		def next
			Component.synthesize(@game, @cla, @cid, :next)
		end

		def next= nxt
			@game.store.update_component @cid, nxt, :next
		end
	end

	class Entity
		attr_reader :game
		attr_reader :id

		def initialize game, id
			@game = game
			@id = id
		end

		def hash; @id.hash; end

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
		alias_method :to_s, :inspect
	end
end