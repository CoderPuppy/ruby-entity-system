class Store::Sub < Store
	def initialize db, prefix
		@db = db
		@prefix = prefix
	end

	def apply batch
		@db.apply Hash[*batch.map do |k, v|
			["#{@prefix}#{k}", v]
		end.flatten]
		self
	end

	def get key
		@db["#{@prefix}#{key}"]
	end

	def _range from, to
		@db._range("#{@prefix}#{from}", "#{@prefix}#{to}").map do |kv|
			[kv.first[@prefix.length..-1], kv.last]
		end
	end
end