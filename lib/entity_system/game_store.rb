module EntitySystem
	class GameStore
		def initialize store
			@store = store
		end

		def max_eid
			@store["entity:max"].to_i
		end

		def max_eid= eid
			@store["entity:max"] = eid.to_s
		end

		def entities
			@store.range gte: "entity:0", lte: "entity:9"
		end

		def spawn
			eid = max_eid
			self.max_eid += 1
			@store["entity:#{eid}"] = eid
			eid
		end

		def tick
			@store.apply Hash[*(@store.range(gte: "component:next:0", lte: "component:next:9").flat_map do |k, v|
				[k.gsub(/^component:next/, "component:prev"), v]
			end)]
		end

		def max_cid
			@store["component:max"].to_i
		end

		def max_cid= cid
			@store["component:max"] = cid.to_s
		end

		def max_comp_id(eid, ctype)
			@store["entity:#{eid}:#{ctype}:max"].to_i
		end

		def set_max_comp_id(eid, ctype, id)
			@store["entity:#{eid}:#{ctype}:max"] = id
		end

		def components eid, type = nil
			if type == nil
				@store.range(gte: "entity:#{eid}:", lte: "entity:#{eid}:\177").map do |k, v|
					type, id = *k.split(":")[2..3]
					[type, id.to_i]
				end
			else
				@store.range(gte: "entity:#{eid}:#{type}:0", lte: "entity:#{eid}:#{type}:9").map do |k, v|
					k.split(":")[3]
				end
			end
		end

		def component(eid, ctype, id)
			comp = @store["entity:#{eid}:#{ctype}:#{id}"]
			comp.to_i if comp
		end

		def add_component eid, component
			cid = max_cid
			self.max_cid += 1
			if component.class.singular
				id = "main"
			else
				id = max_comp_id eid, component.class.id
				self.set_max_comp_id(eid, component.class.id, id + 1)
			end
			@store["component:next:#{cid}"] = "#{eid}-#{cid}"
			@store["component:next:#{cid}:type"] = component.class.id
			component.members.each_with_index do |k, i|
				set_component_data cid, :next, k, component[i]
			end
			@store["entity:#{eid}:#{component.class.id}:#{id}"] = cid
			cid
		end

		def component_type cid, time
			@store["component:#{time}:#{cid}:type"]
		end

		def component_data cid, time, key
			GameStore.unserialize(@store["component:#{time}:#{cid}:-#{key}"])
		end

		def set_component_data cid, time, key, val
			@store["component:#{time}:#{cid}:-#{key}"] = GameStore.serialize(val)
		end

		def self.serialize v
			case v
			when Fixnum
				type = "int"
			when Float
				type = "float"
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
			when "float"
				val = Float(val)
			when "str"
			when "sym"
				# i know this is bad
				val = val.to_sym
			when "nil"
				val = nil
			when "set"
				val = Set.new JSON.parse(val).map(&method(:unserialize))
			else
				raise "Unknown type: #{type}"
			end
			val
		end
	end

	# entity:max
	# entity:<eid>
	# entity:<eid>:<component_type>:<id> = cid

	# component:max
	# component:next:<cid>
	# component:next:<cid>:<var> = value
end