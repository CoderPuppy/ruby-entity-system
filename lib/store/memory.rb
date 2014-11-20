class Store::Memory < Store
	def initialize
		@data = {}
	end

	def apply batch
		@data.merge! batch
		@data.delete_if { |k, v| v == nil }
		self
	end

	def get key
		@data[key]
	end

	def _range from, to
		@data.find_all { |key, val| key >= from && key <= to }.map { |key, val| [key, val] }
	end
end