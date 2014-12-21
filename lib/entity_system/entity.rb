module EntitySystem
	class ComponentContainer
		attr_reader :game, :entity
		attr_reader :eid, :id
		attr_reader :cla, :cid
		attr_reader :next, :prev

		def initialize entity, cla, cid, id
			@entity = entity
			@game = entity.game
			@eid = entity.id
			@cla = cla
			@cid = cid
			@id = id
			@next = Component.synthesize @game, @cla, @eid, @cid, :next
			@prev = Component.synthesize @game, @cla, @eid, @cid, :prev
		end

		def enabled?
			@game.store.enabled? @cid
		end

		def enable
			@game.store.enable @cid
			@game.processes.each do |process|
				process.add @entity, self
			end
			self
		end

		def disable
			@game.store.disable @cid
			@game.processes.each do |process|
				process.remove @entity, self
			end
			self
		end

		def type; @cla.id; end

		def [] time
			case time
			when :next
				@next
			when :prev
				@prev
			else
				raise ArgumentError, "Invalid time: #{time}"
			end
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

		def remove cla, id = :main
			comp = @components[[cla, id]]
			@components.delete [cla, id]
			@game.processes.each do |process|
				process.remove self, comp
			end
			self
		end

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

		def [] cla, id = :main
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
					@components[[cla, id]] = ComponentContainer.new(self, cla, cid, id)
				end
			end
		end

		def enable cla, id = :main
			self[cla, id].enable
			self
		end

		def disable cla, id = :main
			@components.delete [[cla, id]]
			self[cla, id].disable
			self
		end

		def inspect
			"#e#{@id}"
		end
		alias to_s inspect
	end
end