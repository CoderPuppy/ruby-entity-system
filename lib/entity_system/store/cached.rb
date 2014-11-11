module EntitySystem
	class Store::Cached < Store
		def initialize db
			@db = db
			@cache = Store::Memory.new
			@working = {}
		end

		def load opts = {}
			@db.range(opts).each do |k, v|
				@cache[k] = v
			end
			self
		end

		def unload opts = {}
			batch = @cache.batch
			@cache.range(opts).each do |k, v|
				batch.del k
			end
			batch.apply
			self
		end

		def apply batch
			@cache.apply batch
			@working.merge! batch
			@working.delete_if { |k, v| v == nil }
			self
		end

		def get key
			val = @cache[key]
			if val == nil
				val = @db[key]
				@cache[key] = val
			end
			val
		end

		def _range from, to
			# @data.find_all { |key, val| key >= from && key <= to }.map { |key, val| [key, val] }
			@cache._range from, to
		end

		def save
			@db.set_batch @working
			@working = {}
			self
		end
	end
end