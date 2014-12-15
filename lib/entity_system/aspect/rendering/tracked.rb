module EntitySystem
	Component::Tracked = Component.new priority: 0
	class Process::Tracked < Process
		def initialize game
			super
			@tracked = []
		end

		def tracked
			ComputedBox.new do
				@tracked
			end
		end

		def handles? entity
			entity[Component::Tracked]
		end

		def tick
			# log :tracked, :tick, @entities
			@tracked = begin
				@entities
					.values
					.map { |e| [e, e[Component::Tracked].next.priority] }
					.sort { |a, b| a.last <=> b.last }
					.map { |e| e.first }
			end
		end
	end
	class Process::TrackedLoadArea < Process
		def initialize game, tracked
			super
			@tracked = tracked
		end

		def after;[ Process::Teleport, Process::Tracked, Process::TrackedRender ];end

		def handles? entity
			false
		end

		def tick
			@tracked.get
				.map { |e| [e, e[Component::Area]] }
				.select { |e| e.last != nil }
				.each do |e|
					entity, area = e
					prev_area = area.prev.area
					next_area = area.next.area
					next if prev_area == next_area
					@game.unload entity.id
					@game.unload *@game.query(Component::Area => {area: prev_area})
					@game.load @game.query_unloaded(Component::Area => {area: next_area})
					@game.load entity.id
				end
		end
	end
	class Process::TrackedRender < Process
		def initialize game, node, tracked
			super
			@node = node
			@tracked = tracked
		end

		def after;[ Process::Tracked ];end

		def handles? entity
			false
		end

		def tick
			e = @tracked.get
				.map { |e| [e, e[Component::Position]] }
				.find { |e| e.last != nil }
			return unless e
			entity, pos = *e
			pos = pos.next
			width = `window.innerWidth`
			height = `window.innerHeight`
			@node.style do
				left (width/2 - pos.x).px
				bottom (height/2 - pos.y).px
			end
		end
	end
end