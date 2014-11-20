class Store::ObjectStore
	attr_reader :store

	def initialize store
		@store = store
		@modules = {}
	end

	def keys
		@store.range(gte: "R", lte: "R\177").map do |kv|
			kv.first[1..-1]
		end
	end

	def objects
		@store.range(gte: "S", lte: "S\177").map do |kv|
			kv.first[1..-1].split(":").first.to_i
		end
	end

	def register key, id
		ref id
		@store["R#{key}"] = id
		id
	end

	def lookup key
		id = @store["R#{key}"]
		return nil if id == nil
		id.to_i
	end

	def gen_id
		id = @store["max_id"].to_i
		@store["max_id"] = id + 1
		id
	end

	def add obj, id = gen_id
		typ = type(obj)
		@store["S#{id}$type"] = "#{typ.first}:-:#{typ.last}"
		@modules[typ.first].send "serialize_#{typ.last}", obj, Store::Sub.new(@store, "S#{id}:"), self
		id
	end

	def get id
		id = lookup id unless id.is_a? Numeric

		typ = @store["S#{id}$type"]
		return nil if typ == nil
		typ = typ.split(":-:")
		raise "Unknown type: #{typ.ai}" unless @modules[typ.first]
		@modules[typ.first].send "synthesize_#{typ.last}", Store::Sub.new(@store, "S#{id}:"), self
	end
	alias_method :[], :get

	def get_unserialize id
		id = lookup id unless id.is_a? Numeric

		typ = @store["S#{id}$type"]
		return nil if typ == nil
		typ = typ.split(":-:")
		raise "Unknown type: #{typ.ai}" unless @modules[typ.first]
		@modules[typ.first].send "unserialize_#{typ.last}", Store::Sub.new(@store, "S#{id}:"), self
	end

	def ref id
		@store["S#{id}$refs"] = refs(id) + 1
	end

	def refs id
		@store["S#{id}$refs"].to_i
	end

	def del id
		if id.is_a? Numeric
			refs = self.refs id
			@store["S#{id}$refs"] = refs - 1
			refs -= 1
			if refs == 0
				typ = @store["S#{id}$type"]
				return if typ == nil
				typ = typ.split(":-:")
				raise "Unknown type: #{typ.ai}" unless @modules[typ.first]
				@store.del "S#{id}$type"
				@store.del "S#{id}$refs"
				@modules[typ.first].send "delete_#{typ.last}", Store::Sub.new(@store, "S#{id}:"), self
			end
		else
			key = id
			id = lookup(id)
			if id
				del id
				@store.del "R#{key}"
			end
		end
		self
	end
	
	def []= key, obj
		key = key.to_s
		id = add obj
		del key
		register key, id
		get key
	end

	def register_module id, mod
		@modules[id.to_s] = mod
		self
	end

	def type obj
		type = @modules
			.map { |id, mod| [id, mod, mod.type(obj)] }
			.detect { |res| String === res.last || Symbol === res.last }
		raise "Cannot handle: #{obj.ai}" if type == nil
		[type.first, type.last]
	end
end