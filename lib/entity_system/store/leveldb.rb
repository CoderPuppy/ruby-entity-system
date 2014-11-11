require "leveldb-native"

module EntitySystem
	class Store::LevelDB < Store
		attr_reader :db

		def initialize path
			@db = LevelDBNative::DB.new path
		end

		def apply batch
			@db.batch do |b|
				batch.each do |key, val|
					if val == nil
						b.delete key
					else
						b[key] = val
					end
				end
			end
		end

		def get key
			@db[key]
		end

		def _range from, to
			@db.iterator({from: from, to: to})
		end

		def close
			@db.close
			self
		end
	end
end