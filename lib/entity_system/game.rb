module EntitySystem
	class Game
		attr_reader :entities
		attr_reader :processes, :ticking_processes

		def initialize(store)
			@store = store
			@entities = Hash.new
			# @entities = EntityStore.new @store
			@processes = Set.new
			@ticking_processes = []
			@process_afters = {}
		end

		def init
			sort
		end

		def spawn
			entity = Entity.new self
			@entities[entity.uuid] = entity
			entity
		end

		def add cla, *args, &blk
			process = cla.new self, *args, &blk
			@processes << process
			@ticking_processes << process if process.respond_to? :tick
			@process_afters[process.id] = [Set.new(process.after.map(&:id)), [Set.new(process.after.map(&:id))]]
			process.before.each do |before|
				@process_afters[before.id].first << process.id
				@process_afters[before.id].last.last << process.id
			end
			@entities.each do |uuid, entity|
				process.add entity if process.handles? entity
			end
			process
		end

		def remove process
			@processes.delete process
			@ticking_processes.delete process
			self
		end

		def sort
			processes = Hash[@processes.map { |process| [process.id, process] }]
			processes.each do |id, process|
				process.before.each do |before|
					@process_afters[before.id].first << id
					@process_afters[before.id].last.last << id
				end
			end
			while true
				any = false
				@process_afters.each do |k, after|
					new_procs = Set.new
					after.last.last.each do |id|
						process = processes[id]
						unless process.after.empty?
							any = true
							new_procs.merge process.after
							if process.after.include? k
								raise "Cyclic Dependency between #{k} and #{process.id}"
							end
						end
					end
					after.first.merge new_procs
					after.last << new_procs
				end
				break unless any
			end
			@ticking_processes.sort! do |a, b|
				a_after = @process_afters[a.id].first
				b_after = @process_afters[b.id].first
				if a_after.include? b.id
					1
				elsif b_after.include? a.id
					-1
				else
					0
				end
			end
		end

		def tick
			@entities.each do |k, entity|
				entity.components.each do |k, container|
					container.tick
				end
			end
			@ticking_processes.each do |process|
				process.tick if process.enabled?
			end
		end
	end
end