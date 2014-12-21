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

		def [] query
			if query.is_a? Fixnum
				entity query
			else
				self.query query
			end
		end

		def entity id
			@entities[id] ||= Entity.new(self, id)
		end

		def entities
			@store.entities.lazy.map { |id| entity id }
		end

		def query query
			def intersection h
				h.values.reduce { |acc, ele| acc.to_set & ele }
			end

			entities = Hash[*query.flat_map do |type, data|
				type = type.id if type.respond_to? :id

				[type, if data.empty?
					@store.by_type type
				else
					props = Hash[*data.flat_map{|k, v|
						# find all the components that has the value `v` for the key `k`
						[k, @store.query(type, k, v)]
					}]

					# this is what components verify the constraint
					# after this we need to find the entity
					# the component doesn't matter
					intersection props
				end.map{|p|p.first}]
			end]

			intersection(entities).map { |id| entity id }
		end

		def query_unloaded query
			Enumerator.new do |out, done|
				to_load = query.length
				loaded = 0
				entities = []
				query
					.map do |type, data|
						type = type.id if type.respond_to? :id

						if data.empty?
							@store.by_type_unloaded type
						else
							Enumerator.new do |out, done|
								props = []
								to_load_i = data.length
								loaded_i = 0
								data.each do |k, v|
									# find all the components that has the value `v` for the key `k`
									res = []
									@store.query_unloaded(type, k, v).each do |kv|
										res << kv
									end.onend do
										if Array === props
											props = res.to_set
										else
											props &= res
										end
										loaded_i += 1
										if loaded_i >= to_load_i
											props.each do |v|
												out << v
											end
											done[]
										end
									end
								end
							end.lazy
						end.map{|p|p.first}
					end
					.each do |e|
						res = []
						e.each do |v|
							res << v
						end.onend do
							if Array === entities
								entities = res.to_set
							else
								entities &= res
							end
							loaded += 1
							if loaded >= to_load
								entities.each do |id|
									out << id
								end
								done[]
							end
						end
					end
			end.lazy
		end

		def load *ids, &blk
			to_load = ids.length
			loaded = 0
			ids.each_with_index do |id, i|
				res = []
				if id.respond_to? :each
					id
				else
					[id]
				end.each do |v|
					res << v
				end.onend do
					ids[i] = res
					loaded += 1
					if loaded >= to_load
						ids.flatten!
						# log ids.join(", ")
						@store.load *ids do
							# log @store.entities.join(", ")
							reassign
							blk.call if blk
						end
					end
				end
			end
			self
		end

		def unload *ids
			ids = ids.flatten.map do |id|
				if id.respond_to? :id
					id.id
				else
					id
				end
			end
			ids.each do |id|
				entity = entity id
				@processes.each do |process|
					process.remove entity
				end
				@entities.delete id
			end
			@store.unload *ids
			self
		end

		def reassign *processes
			processes = @processes.to_a if processes.empty?
			processes = find_processes *processes
			@store.entities.each do |id|
				e = entity(id)
				processes.each do |process|
					next unless @processes.include? process
					process.add e
				end
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
			@process_afters[cla] ||= Set.new
			@process_afters[cla] += process.after
			sort
			reassign process
			process
		end

		def find_processes *processes
			return @processes.to_a if processes.empty?
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
				@process_afters.delete process.class
			end
			@processes -= processes
			@ticking_processes.delete_if {|proc| processes.include? proc}
			sort
			self
		end

		def enable *processes
			processes = find_processes(*processes)
			reassign *processes
			@processes += processes
			@ticking_processes += processes
			sort
			self
		end

		def disable *processes
			processes = find_processes(*processes).to_set
			processes.each do |process|
				process.remove process.entities.first.last until process.entities.empty?
			end
			@processes -= processes
			@ticking_processes.delete_if {|proc| processes.include? proc}
			self
		end

		def pause *processes
			processes = find_processes(*processes).to_set
			processes.each do |process|
				process.pause
			end
			self
		end

		def unpause *processes
			processes = find_processes(*processes).to_set
			processes.each do |process|
				process.unpause
			end
			self
		end

		def sort
			@ticking_processes = @process_afters.tsort.map do |cla|
				(@process_classes[cla] || []).first
			end.select do |proc|
				proc.respond_to? :tick
			end
		end

		def save
			@store.save
			self
		end

		def tick_count
			@store.tick_count
		end

		def tick
			@store.tick
			@ticking_processes.each do |process|
				# log :ticking, process.id
				process.tick unless process.paused?
			end
		end
	end
end