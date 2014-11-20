require "bigdecimal"
require "set"

module Store::ObjectStore::StdLib
	def self.type obj
		case obj
		when String
			:string
		when Symbol
			:symbol
		when Fixnum
			:fixnum
		when Float
			:float
		when BigDecimal
			:bigdecimal
		when Hash
			:hash
		when Set
			:set
		end
	end

	begin # String
		def self.serialize_string obj, raw, store
			raw[""] = obj
		end

		def self.synthesize_string raw, store
			raw[""]
		end
		singleton_class.send :alias_method, :unserialize_string, :synthesize_string

		def self.delete_string raw, store
			raw.del ""
		end
	end

	begin # Symbol
		def self.serialize_symbol obj, raw, store
			raw[""] = obj
		end

		def self.synthesize_symbol raw, store
			raw[""].to_sym
		end
		singleton_class.send :alias_method, :unserialize_symbol, :synthesize_symbol

		def self.delete_symbol raw, store
			raw.del ""
		end
	end

	begin # Fixnum
		def self.serialize_fixnum obj, raw, store
			raw[""] = obj
		end

		def self.synthesize_fixnum raw, store
			raw[""].to_i
		end
		singleton_class.send :alias_method, :unserialize_fixnum, :synthesize_fixnum

		def self.delete_fixnum raw, store
			raw.delete ""
		end
	end

	begin # Float
		def self.serialize_float obj, raw, store
			raw[""] = obj
		end

		def self.synthesize_float raw, store
			raw[""].to_f
		end
		singleton_class.send :alias_method, :unserialize_float, :synthesize_float

		def self.delete_float raw, store
			raw.delete ""
		end
	end

	begin # BigDecimal
		def self.serialize_bigdecimal obj, raw, store
			raw[""] = obj
		end

		def self.synthesize_bigdecimal raw, store
			BigDecimal(raw[""])
		end
		singleton_class.send :alias_method, :unserialize_bigdecimal, :synthesize_bigdecimal

		def self.delete_bigdecimal raw, store
			raw.delete ""
		end
	end

	begin # Hash
		def self.serialize_hash obj, raw, store
			obj.each do |k, v|
				k_hash = k.hash
				k_id = store.add k
				store.ref k_id

				v_hash = v.hash
				v_id = store.add v
				store.ref v_id

				raw[">#{k_hash}"] = "#{k_id}:#{v_id}"
				raw["<#{v_hash}"] = "#{k_id}:#{v_id}"
			end
		end

		def self.synthesize_hash raw, store
			SynthesizedHash.new raw, store
		end

		def self.unserialize_hash raw, store
			Hash[*raw.range.flat_map do |kv|
				kv.last.split(":").map(&:to_i).map(&store.method(:get_unserialize))
			end]
		end

		def self.delete_hash raw, store
			raw.range(gte: ">", lte: ">\177").flat_map do |kv|
				kv.last.split(":").map(&:to_i).each(&store.method(:del))
			end
		end

		class SynthesizedHash < Hash
			def initialize raw, store
				@raw = raw
				@store = store
			end

			def unserialize
				StdLib.unserialize_hash(@raw, @store)
			end

			def hash
				unserialize.hash
			end

			def []= key, val
				prev = @raw[">#{key.hash}"]
				if prev
					prev.split(":").map(&:to_i).map(&@store.method(:del))
				end
				k_id = @store.add key
				v_id = @store.add val
				@raw[">#{key.hash}"] = "#{k_id}:#{v_id}"
				@raw["<#{key.hash}"] = "#{k_id}:#{v_id}"
				@store[v_id]
			end

			def [] key
				@store[@raw[">#{key.hash}"].split(":").last.to_i]
			end

			def get_unserialize key
				@store.get_unserialize @raw[">#{key.hash}"].split(":").last.to_i
			end

			def keys
				@raw.range(gte: ">", lte: ">\177").flat_map do |kv|
					@store[kv.last.split(":").first.to_i]
				end
			end

			def values
				@raw.range(gte: ">", lte: ">\177").flat_map do |kv|
					@store[kv.last.split(":").last.to_i]
				end
			end
		end
	end

	begin # Set
		def self.serialize_set obj, raw, store
			obj.each do |v|
				id = store.add v
				raw[id] = id
			end
		end

		def self.synthesize_set raw, store
			SynthesizedSet.new raw, store
		end

		class SynthesizedSet < Set
			def initialize raw, store
				@raw = raw
				@store = store
			end

			def to_a
				@raw.range.map { |kv| @store[kv.last.to_i] }
			end

			def add o
				id = @store.add o
				@raw[id] = id
			end
			alias_method :<<, :add
		end

		def self.unserialize_set raw, store
			Set.new raw.range.map { |kv| store.get_unserialize kv.last.to_i }
		end
	end
end