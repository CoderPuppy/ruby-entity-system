module EntitySystem
	module Component
		def self.new(*fields, &blk)
			impl = proc do
				define_method :id do
					self.class.id
				end

				def self.id
					@id ||= name.split("::").last.gsub(/([a-z])([A-Z])/) { |m| "#{m[0]}_#{m[1].downcase}" }.downcase.to_sym
				end

				def self.singular; true; end

				define_method :inspect do
					if self.length > 0
						# "#<#{self.class.name.split("::").last} #{self.to_h.map { |k, v| v.inspect }.join " "}>"
						"#<#{self.class.name.split("::").last} #{self.to_h.map { |k, v| "#{k}=#{v.inspect}" }.join " "}>"
						# "#{self.class.name.split("::").last}(#{self.to_a.map(&:inspect).join ", "})"
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

		def self.synthesize game, cla, cid, time
			Class.new cla do
				attr_reader :game
				attr_reader :cla, :cid
				attr_reader :time

				define_singleton_method :name do
					"#{cla.name}::Stored"
				end

				def initialize game, cla, cid, time
					@game = game
					@cla = cla
					@cid = cid
					@time = time
				end

				cla.members.each do |k|
					define_method k do
						@game.store.component_data(@cid, @time, k)
					end

					define_method "#{k}=" do |v|
						game.store.set_component_data(@cid, @time, k, v)
						v
					end
				end

				def class; @cla; end
				def === cla; super || @cla == cla; end

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

				def to_h
					Hash[*@cla.members.flat_map do |k|
						[k, @game.store.component_data(@cid, @time, k)]
					end]
				end

				def length
					@cla.members.length
				end
			end.new game, cla, cid, time
		end
	end
end