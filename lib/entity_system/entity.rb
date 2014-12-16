module EntitySystem
	class ComponentContainer
		attr_reader :game
		attr_reader :eid, :id
		attr_reader :cla, :cid
		attr_reader :next, :prev

		def initialize game, eid, cla, cid, id
			@game = game
			@eid = eid
			@cla = cla
			@cid = cid
			@id = id
			@next = Component.synthesize @game, @cla, @eid, @cid, :next
			@prev = Component.synthesize @game, @cla, @eid, @cid, :prev
		end

		def type; @cla.id; end

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
			@components = {}

			raise ArgumentError, "Bad ID: #{id}" unless @game.store.entity? id
		end

		def hash; @id.hash; end

		def << component
			cid = @game.store.add_component @id, component[:id], component
			comp = self[component.class, component.id]
			@game.processes.each do |process|
				process.add self, comp
			end
			self
		end

		# This doesn't work
		# def remove id
		# 	@components.delete id
		# 	@game.processes.each do |process|
		# 		process.remove self if !process.handles? self
		# 	end
		# end

		def list cla = nil
			if cla
				@game.store.components(@id, cla.id).map do |comp|
					self[cla, comp.first]
				end
			else
				@game.store.components(@id).map do |comp|
					self[Component.from_id(comp[0]), comp[1]]
				end
			end
		end

		def [] cla, id = "main"
			if id == nil
				list cla
			else
				comp = @components[[cla, id]]
				# log @id, cla.name, id, comp
				if comp
					comp
				else
					cid = @game.store.component @id, cla.id, id
					# raise ArgumentError, "Bad ID: #{id} for #{self}[#{cla}]" unless cid
					# log @id, cla.name, id, cid
					return nil unless cid
					@components[[cla, id]] = ComponentContainer.new(@game, @id, cla, cid, id)
				end
			end
		end

		def inspect
			"#<Entity:#{@id}>"
		end
		alias_method :to_s, :inspect
	end
end