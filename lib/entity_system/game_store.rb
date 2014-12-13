module EntitySystem
	# entity:max
	# entity:<eid>
	# entity:<eid>:<component_type>:<id> = cid

	# component:max
	# component:<time>><cid>
	# component:<time>><cid>:<key> = value
	# component:<time><<type>:<key>:<val>:<cid> = <cid>

	class GameStore
		def initialize
			@main_store = yield :main
			@next_store = yield :next
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

		def tick
			@prev_store = @next_store.dup
			@next_store["tick"] = @next_store["tick"].to_i + 1
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
			val = GameStore.serialize val
			prefix = "component<#{type}:-#{key}:#{val}"
			from_time(time)
				.range(gte: "#{prefix}:", lte: "#{prefix}:~")
				.map { |kv| @next_store["component:#{kv.last}"].split("-").map(&:to_i) }
		end

		def add_component eid, id, component
			cid = max_cid
			self.max_cid += 1
			@main_store["component:#{cid}"] = "#{eid}-#{cid}"
			update_component cid, component, :next
			update_component cid, component, :prev
			@main_store["entity:#{eid}:#{component.class.id}:#{id}"] = cid
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
			# log "BAD" if @prev_store["component>#{cid}:-#{key}"] != prev
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