module EntitySystem
	module Component
		def initialize *args
			data = self.class.fields.values
			index = 0
			args.each do |arg|
				if arg.is_a? Hash
					arg.each do |k, v|
						index = self.class.members.index(k)
						raise ArgumentError, "#{k} is an invalid key" if index == nil
						data[index] = v
					end
				else
					data[index] = arg
					index += 1
				end
			end
			super *data
		end
		
		def self.name_from_id id
			id.split("_").map{|part| part[0].upcase + part[1..-1]}.join("")
		end
		def self.from_id id
			const_get name_from_id(id)
		end

		def self.new(*fields, &blk)
			fields = Hash[*fields.flat_map do |field|
				if field.is_a? Hash
					field.flat_map { |k, v| [k, v] }
				else
					[field, nil]
				end
			end]

			fields[:id] = "main"

			impl = proc do
				include Component

				@fields = fields
				def self.fields; @fields; end
				def fields; self.class.fields; end

				def self.[] *args, &blk
					new *args, &blk
				end

				def type
					self.class.id
				end

				def values
					fields.keys.map do |k|
						self[k]
					end
				end

				def == other
					if other.is_a? Component
						values == other.values
					else
						super
					end
				end

				def self.id
					@id ||= name.split("::").last.gsub(/([a-z])([A-Z])/) { |m| "#{m[0]}_#{m[1].downcase}" }.downcase.to_sym
				end

				def inspect
					if self.length > 0
						# "#<#{self.class.name.split("::").last} #{self.to_h.map { |k, v| v.inspect }.join " "}>"
						"#<#{self.class.name.split("::").last} #{self.to_h.map { |k, v| "#{k}=#{v.inspect}" }.join " "}>"
						# "#{self.class.name.split("::").last}(#{self.to_a.map(&:inspect).join ", "})"
					else
						"#{self.class.name.split("::").last}"
					end
				end
				alias_method :to_s, :inspect

				module_eval &blk if blk
			end

			if fields.empty?
				Class.new do
					def length; 0; end
					def members; []; end
					def self.members; []; end
					def [] k; nil; end
					def []= k; nil; end
					def to_h; {}; end

					module_eval &impl
				end
			else
				Struct.new *fields.keys do
					def to_h
						Hash[fields.keys.map{|k|[k, self[k]]}]
					end

					def [] k
						if k.is_a? Fixnum
							super
						else
							idx = fields.keys.index(k)
							raise ArgumentError, "Invalid key: #{k}" if idx == nil
							super idx
						end
					end

					def []= k, v
						if k.is_a? Fixnum
							super
						else
							idx = fields.keys.index(k)
							raise ArgumentError, "Invalid key: #{k}" if idx == nil
							super idx, v
						end
					end

					module_eval &impl
				end
			end
		end

		def self.synthesize game, cla, eid, cid, time
			synth_cla = Class.new cla do
				@cla = cla

				attr_reader :game
				attr_reader :cla, :cid
				attr_reader :eid
				attr_reader :time

				def self.name
					"#{@cla.name}::Stored"
				end

				def initialize game, cla, eid, cid, time
					@game = game
					@cla = cla
					@eid = eid
					@cid = cid
					@time = time
				end

				cla.members.each do |k|
					define_method k do
						@game.store.component_data @cid, @time, k
					end

					define_method "#{k}=" do |v|
						game.store.set_component_data @cid, @time, k, v
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
			end
			# `debugger`
			synth_cla.new game, cla, eid, cid, time
		end
	end
end