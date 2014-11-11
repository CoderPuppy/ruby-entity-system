module EntitySystem
	class Store
		def batch
			Batch.new(self)
		end

		def [] key
			if key.respond_to? :to_str
				get key.to_str
			else
				range key
			end
		end

		def put key, val
			batch.put(key, val).apply
		end
		def []= key, val
			put key, val
			val
		end

		def delete key = {}
			batch.delete(key).apply
			self
		end
		alias :del :delete

		RANGE_DEFAULT_OPTS = {
			gte: "",
			lte: "\177"
		}
		def range opts = {}
			opts = RANGE_DEFAULT_OPTS.merge opts
			from = opts[:gte] || ""
			to = opts[:lte] || "\177"
			if opts[:gt]
				if opts[:gt] == ""
					from = 1.chr
				else
					from = opts[:gt][0..-2] + (opts[:gt][-1].ord + 1).chr
				end
			end
			if opts[:lt]
				if opts[:lt] == ""
					to = 0.chr
				else
					to = opts[:lt][0..-2] + (opts[:lt][-1].ord - 1).chr
				end
			end
			_range from, to
		end

		def save; self; end
		def close; self; end

		class Batch
			def initialize(store)
				@store = store
				@data = {}
			end

			def put key, val
				@data[key] = val
				self
			end
			def []= key, val
				put key, val
				val
			end

			def delete key = {}
				if key.respond_to? :to_str
					put key, nil
				else
					@store.range(key).each do |key, val|
						put key, nil
					end
				end
				self
			end
			alias :del :delete

			def apply
				@store.apply @data
			end
		end

		autoload :LevelDB, File.expand_path("../store/leveldb.rb", __FILE__)
	end
end