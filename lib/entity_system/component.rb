module EntitySystem
	module Component
		def self.new(*fields, &blk)
			impl = proc do
				def id
					self.class.id
				end

				def self.id
					@id ||= name.split("::").last.gsub(/([a-z])([A-Z])/) { |m| "#{m[0]}_#{m[1].downcase}" }.downcase.to_sym
				end

				def self.singular; true; end

				def inspect
					if self.length > 0
						# "#<#{self.class.name.split("::").last} #{self.to_h.map { |k, v| "#{k}=#{v.inspect}" }.join " "}>"
						"#{self.class.name.split("::").last}(#{self.to_a.map(&:inspect).join ", "})"
					else
						"#{self.class.name.split("::").last}"
					end
				end

				instance_eval &blk if blk
			end

			if fields.empty?
				Class.new do
					def self.[]
						new
					end

					def length; 0; end
					def members; []; end
					def self.members; []; end
					def [] i; nil; end

					instance_eval &impl
				end
			else
				Struct.new *fields do
					instance_eval &impl
				end
			end
		end

		class Synthesized
			attr_reader :game
			attr_reader :cla, :cid
			attr_reader :time

			def initialize(game, cla, cid, time)
				@game = game
				@cla = cla
				@cid = cid
				@time = time
				cla.members.each do |k|
					self.define_singleton_method(k) do
						@game.store.component_data(@cid, @time, k)
					end

					self.define_singleton_method("#{k}=") do |v|
						game.store.set_component_data(@cid, @time, k, v)
					end
				end
			end

			def id
				@cla.id
			end

			def [] k
				if k.is_a? Fixnum
					@game.store.component_data @cid, @time, cla.members[k]
				else
					@game.store.component_data @cid, @time, k
				end
			end

			def []= k, v
				if k.is_a? Fixnum
					@game.store.set_component_data @cid, @time, cla.members[k], v
				else
					@game.store.set_component_data @cid, @time, k, v
				end
			end

			def to_a
				@cla.members.map do |k|
					@game.store.component_data @cid, @time, k
				end
			end

			def length
				@cla.members.length
			end

			def inspect
				if self.length > 0
					# "#<#{@cla.name.split("::").last} #{self.to_h.map { |k, v| "#{k}=#{v.inspect}" }.join " "}>"
					"#{@cla.name.split("::").last}(#{self.to_a.map(&:inspect).join ", "})"
				else
					"#{@cla.name.split("::").last}"
				end
			end
		end
	end
end