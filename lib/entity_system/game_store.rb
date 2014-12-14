module EntitySystem
	## Main Store
	# entity:max
	# entity:<eid>
	# entity:<eid>:<component_type>:<id> = cid

	# component:max
	# component><cid> = <eid>-<id>-<cid>
	# component<<type>:<cid> = <cid>

	# Timed Store
	# component><cid>:<key> = value
	# component<<type>:<key>:<val>:<cid> = <cid>

	class GameStore
		attr_reader :main_store, :next_store, :prev_store

		def initialize
			@main_store = Store::Cached.new yield(:main, true), yield(:main, false)
			@next_store = Store::Cached.new yield(:next, true), yield(:next, false)
			tick
		end

		def stores
			{
				main: @main_store,
				next: @next_store,
				prev: @prev_store
			}
		end

		def max_eid
			@main_store["entity:max"].to_i
		end

		def max_eid= eid
			@main_store["entity:max"] = eid.to_s
		end

		def entity? eid
			!!@main_store["entity:#{eid}"]
		end

		def entities
			@main_store
				.range(gte: "entity:0", lte: "entity:9")
				.select { |kv| kv.first.match(/^entity:\d+$/) }
				.map { |kv| kv.last.to_i }
		end

		def spawn
			eid = max_eid
			self.max_eid += 1
			@main_store["entity:#{eid}"] = eid
			eid
		end

		def load *ids, &blk
			to_load = 0
			loaded = 0
			onloaded = ->(name) do
				to_load += 1
				iloaded = false
				-> do
					next if iloaded
					iloaded = true
					loaded += 1
					if loaded >= to_load && blk
						blk[]
					end
				end
			end
			ids.onend(&onloaded["ids"]).each do |eid|
				t = onloaded[eid]
				@main_store.load(gte: "entity:#{eid}", lte: "entity:#{eid}\xFF") do
					tt = onloaded["#{eid} components"]
					components(eid).each do |comp|
						ttt = onloaded[comp.join(":") + " data"]
						@main_store.load gte: "component>#{comp.last}", lte: "component>#{comp.last}", &onloaded[comp.join(":")]
						@next_store.load(gte: "component>#{comp.last}", lte: "component>#{comp.last}\xFF") do
							@next_store.range(gte: "component>#{comp.last}", lte: "component>#{comp.last}\xFF").each do |kv|
								cid, key = *kv.first.split(">")[1..-1].join(">").split(":")
								@next_store.load gte: "component<#{key}:#{kv.last}:#{cid}", lte: "component<#{key}:#{kv.last}:#{cid}", &onloaded[comp.join(":") + " data #{key}"]
							end
							ttt[]
						end
					end.onend &tt
					t[]
				end
			end
		end

		def unload *ids
			save
			main_batch = @main_store.batch
			next_batch = @next_store.batch
			ids.each do |eid|
				components(eid).each do |comp|
					main_batch.delete "component>#{comp.last}"
					@next_store.range(gte: "component>#{comp.last}", lte: "component>#{comp.last}\xFF").each do |kv|
						next_batch.delete kv.first
						cid, key = *kv.first.split(">")[1..-1].join(">").split(":")
						next_batch.delete "component<#{key}:#{kv.last}:#{cid}"
					end
				end
				main_batch.delete gte: "entity:#{eid}", lte: "entity:#{eid}\xFF"
			end
			main_batch.apply
			next_batch.apply
			self
		end

		def save
			@main_store.save
			@next_store.save
		end

		def tick
			@prev_store = @next_store.cache.dup
			@next_store["tick"] = tick_count + 1
		end

		def tick_count
			@next_store["tick"].to_i
		end

		def max_cid
			@main_store["component:max"].to_i
		end

		def max_cid= cid
			@main_store["component:max"] = cid.to_s
		end

		def max_comp_id eid, ctype
			@main_store["entity:#{eid}:#{ctype}:max"].to_i
		end

		def set_max_comp_id eid, ctype, id
			@main_store["entity:#{eid}:#{ctype}:max"] = id
		end

		def components eid, type = nil
			if type == nil
				@main_store.range(gte: "entity:#{eid}:", lte: "entity:#{eid}:\xFF").map do |k, v|
					type, id = *k.split(":")[2..3]
					[type, id.to_i, v.to_i]
				end
			else
				@main_store.range(gte: "entity:#{eid}:#{type}:", lte: "entity:#{eid}:#{type}:\xFF").map do |k, v|
					[k.split(":")[3], v.to_i]
				end
			end
		end

		def component eid, ctype, id
			comp = @main_store["entity:#{eid}:#{ctype}:#{id}"]
			comp.to_i if comp
		end

		def query type, key, val, time = :next
			type = type.id if type.respond_to? :id
			val = GameStore.serialize val
			prefix = "component<#{type}:-#{key}:#{val}"
			from_time(time)
				.range(gte: "#{prefix}:", lte: "#{prefix}:\xFF")
				.map { |kv| @main_store["component>#{kv.last}"].split("-") }
				.map { |comp| comp[0...-1].map(&:to_i) + [comp.last] }
		end

		def by_type type
			type = type.id if type.respond_to? :id
			prefix = "component<#{type}"
			@main_store
				.range(gte: "#{prefix}:", lte: "#{prefix}:\xFF")
				.map { |kv| @main_store["component>#{kv.last}"].split("-") }
				.map { |comp| comp[0...-1].map(&:to_i) + [comp.last] }
		end

		def query_unloaded type, key, val
			type = type.id if type.respond_to? :id
			val = GameStore.serialize val
			prefix = "component<#{type}:-#{key}:#{val}"
			@next_store.db
				.range(gte: "#{prefix}:", lte: "#{prefix}:\xFF")
				.flat_map { |kv| @main_store.db.range(gte: "component>#{kv.last}", lte: "component>#{kv.last}").map{|kv|kv.last.split("-")} }
				.map { |comp| comp[0...-1].map(&:to_i) + [comp.last] }
		end

		def by_type_unloaded type
			type = type.id if type.respond_to? :id
			prefix = "component<#{type}"
			@main_store.db
				.range(gte: "#{prefix}:", lte: "#{prefix}:\xFF")
				.flat_map { |kv| @main_store.db.range(gte: "component>#{kv.last}", lte: "component>#{kv.last}").map{|kv|kv.last.split("-")} }
				.map { |comp| comp[0...-1].map(&:to_i) + [comp.last] }
		end

		def add_component eid, id, component
			cid = max_cid
			self.max_cid += 1
			type = component.class.id
			@main_store["component>#{cid}"] = [eid, cid, id].join "-"
			@main_store["component<#{type}:#{cid}"] = cid
			update_component cid, component, :next
			update_component cid, component, :prev
			@main_store["entity:#{eid}:#{type}:#{id}"] = cid
			cid
		end

		def update_component cid, component, time = :next
			store = from_time(time)
			store["component>#{cid}:type"] = component.class.id
			store["component<#{component.class.id}:type:#{component.class.id}:#{cid}"] = "#{cid}:type"
			component.members.each_with_index do |k, i|
				set_component_data cid, time, k, component[i]
			end
			cid
		end

		def component_type cid, time
			from_time(time)["component>#{cid}:type"]
		end

		def component_data cid, time, key
			GameStore.unserialize(from_time(time)["component>#{cid}:-#{key}"])
		end

		def set_component_data cid, time, key, val
			val = GameStore.serialize(val)
			type = component_type cid, time
			prev = @prev_store["component>#{cid}:-#{key}"]
			prev = nil if prev == val
			store = from_time(time)
			store["component>#{cid}:-#{key}"] = val
			store["component<#{type}:-#{key}:#{val}:#{cid}"] = cid
		end

		def self.serialize v
			case v
			# when Fixnum
			# 	type = "int"
			# when Float
			# 	type = "float"
			when Numeric
				type = "num"
			when String
				type = "str"
			when Symbol
				type = "sym"
			when NilClass
				type = "nil"
				v = ""
			when Set
				type = "set"
				v = JSON.generate(v.map(&method(:serialize)))
			when Array
				type = "array"
				v = JSON.generate(v.map(&method(:serialize)))
			when Boolean
				type = "bool"
				v = v ? "1" : "0"
			else
				raise "Can't find type for #{v.inspect}"
			end
			"#{type}:#{v}"
		end

		def self.unserialize raw
			return nil if raw == nil
			split = raw.split(":")
			type = split[0]
			val = split[1..-1].join(":")
			case type
			when "int"
				val = Integer(val)
			when "float", "num"
				val = Float(val)
			when "str"
			when "sym"
				# i know this is bad
				val = val.to_sym
			when "nil"
				val = nil
			when "array"
				val = JSON.parse(val).map(&method(:unserialize))
			when "set"
				val = Set.new JSON.parse(val).map(&method(:unserialize))
			when "bool"
				val = case val
				when "1"
					true
				when "0"
					false
				end
			else
				raise "Unknown type: #{type}"
			end
			val
		end

		private
			def from_time time
				case time
				when :next
					@next_store
				when :prev
					@prev_store
				else
					raise ArgumentError, "Bad time: #{time}"
				end
			end
	end
end