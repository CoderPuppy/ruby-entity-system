module EntitySystem::Component
	def self.new(*fields, &blk)
		if fields.empty?
			Class.new do
				def id
					self.class.id
				end

				def self.id
					@id ||= name.split("::").last.gsub(/([a-z])([A-Z])/) { |m| "#{m[0]}_#{m[1].downcase}" }.downcase.to_sym
				end

				def inspect
					"#{self.class.name.split("::").last}"
				end

				def self.[]
					new
				end

				instance_eval &blk if blk
			end
		else
			Struct.new *fields do
				def id
					self.class.id
				end

				def self.id
					@id ||= name.split("::").last.gsub(/([a-z])([A-Z])/) { |m| "#{m[0]}_#{m[1].downcase}" }.downcase.to_sym
				end

				def inspect
					# "#<#{self.class.name.split("::").last} #{self.to_h.map { |k, v| "#{k}=#{v.inspect}" }.join " "}>"
					"#{self.class.name.split("::").last}(#{self.to_a.map(&:inspect).join ", "})"
				end

				instance_eval &blk if blk
			end
		end
	end
end