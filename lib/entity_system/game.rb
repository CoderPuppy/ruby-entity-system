module EntitySystem
	class Game
		attr_reader :store
		attr_reader :processes, :ticking_processes

		def initialize &blk
			@store = GameStore.new &blk
			@processes = Set.new
			@ticking_processes = []
			@disabled_processes = Set.new
			@process_classes = {}
			@process_afters = {}
			@entities = {}
		end

		def init
			sort
		end

		def spawn
			entity @store.spawn
		end

		def entity id
			@entities[id] ||= Entity.new(self, id)
		end

		def query query
			def intersection h
				h.values.reduce { |acc, ele| acc.to_set & ele }
			end

			components = Hash[*query.flat_map do |type, data|
				type = type.id if type.respond_to? :id

				props = Hash[*data.flat_map{|k, v|
					# find all the components that has the value `v` for the key `k`
					[k, @store.query(type, k, v)]
				}]

				intersection = intersection(props)
				# this is what components verify the constraint

				# after this we need to find the entity
				# the component doesn't matter
				[type, intersection.map{|p|p.first}]
			end]

			intersection(components).map { |id| entity id }
		end

		def [] query
			if query.is_a? Fixnum
				entity query
			else
				self.query query
			end
		end

		def add cla, *args, &blk
			process = cla.new self, *args, &blk
			@processes << process
			@ticking_processes << process if process.respond_to? :tick
			cla.ancestors.each do |cla|
				@process_classes[cla] ||= Set.new
				@process_classes[cla] << process
			end
			afters = @process_afters[process.id] ||= [Set.new, [Set.new]]
			afters.first.merge process.after.map(&:id)
			afters.last.last.merge process.after.map(&:id)
			process.before.each do |before|
				@process_afters[before.id] ||= [Set.new, [Set.new]]
				@process_afters[before.id].first << process.id
				@process_afters[before.id].last.last << process.id
			end
			@store.entities.each do |id|
				e = entity(id)
				process.add e if process.handles? e
			end
			process
		end

		def find_processes *processes
			processes.map! do |process|
				if process.is_a? Module
					@process_classes[process].to_a
				else
					process
				end
			end
			processes.flatten!
			processes
		end

		def remove *processes
			processes = find_processes(*processes).to_set
			processes.each do |process|
				process.entities.each do |entity|
					process.remove entity
				end
			end
			@processes -= processes
			@ticking_processes.delete_if {|proc| processes.include? proc}
			self
		end

		def enable *processes
			processes = find_processes(*processes)
			processes.each do |process|
				@store.entities.each do |id|
					e = entity(id)
					process.add e if process.handles? e
				end
			end
			@processes += processes
			@ticking_processes += processes
			sort
			self
		end

		def disable *processes
			processes = find_processes(*processes).to_set
			processes.each do |process|
				process.remove process.entities.first until process.entities.empty?
			end
			@processes -= processes
			@ticking_processes.delete_if {|proc| processes.include? proc}
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
			@store.tick
			@ticking_processes.each do |process|
				process.tick
			end
		end
	end
end