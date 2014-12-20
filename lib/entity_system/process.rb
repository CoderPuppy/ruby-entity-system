module EntitySystem
	class Process
		attr_accessor :paused
		attr_reader :entities

		def initialize game
			@game = game
			@paused = false
			@entities = {}
			@components_by_entity = Hash.new do |h, k|
				h[k] = Set.new
			end
			@components = Hash.new do |h, k|
				if Class === k
					h[k] = Set.new
				elsif Array === k && k.length == 2
					h[k + [:main]]
				elsif Array === k && k.length == 3 && String === k[0]
					h[k] = Set.new
				end
			end
		end

		def id
			self.class.id
		end

		def self.id
			@id ||= name.split("::").last.gsub(/([a-z])([A-Z])/) { |m| "#{m[0]}_#{m[1].downcase}" }.downcase.to_sym
		end

		def after; []; end
		def before; []; end

		def paused?; @paused; end
		def pause
			@paused = true
			self
		end
		def unpause
			@paused = false
			self
		end

		def add entity, component = nil
			if component == nil
				entity.list.each do |comp|
					add entity, comp
				end
			else
				entity = @entities[entity.id] || entity
				component = @components[[entity.id, component.cla, component.id]] || component
				# log :trying, :to, :add, entity.id, component.type, component.id, :to, self.id
				return entity unless handles? entity, component
				unless @components[[entity.id, component.cla, component.id]]
					# log :adding, entity.id, component.type, component.id, :to, self.id
					@entities[entity.id] = entity
					@components_by_entity[entity.id] << [component.type, component.id]
					# log id, entity.id, @components_by_entity[entity.id].to_a.map{|c|c.join ":"}.join(", ")
					@components[component.cla] << [entity, component]
					@components[[:all, entity.id, component.cla]] << component
					@components[[entity.id, component.cla, component.id]] = component
					handle_add entity, component
				end
			end
			entity
		end

		def remove raw_entity, raw_component = nil
			if raw_component == nil
				raw_entity.list.each do |comp|
					remove raw_entity, comp
				end
			else
				# log :trying, :to, :remove, raw_entity.id, raw_component.type, raw_component.id, :from, id
				entity = @entities[raw_entity.id] #|| raw_entity
				# log :no, :entity, raw_entity.id unless entity
				return raw_entity unless entity
				component = @components[[entity.id, raw_component.cla, raw_component.id]]
				# unless component
				# 	log :no, :component, raw_component.type, raw_component.id
				# 	log @components.keys.select{|k|k.is_a?(Array) && k.length == 3}#.map{|k|[k[0].id, k[1].id, k[2]].join(":")}
				# end
				return raw_entity unless component
				# log :removing, entity.id, component.type, component.id, :from, id
				e = @entities[entity.id]
				@components_by_entity[entity.id].delete [component.type, component.id]
				if @components_by_entity[entity.id].empty?
					# log :deleting, entity.id, :from, id
					# log id, entity.id, @components_by_entity[entity.id].to_a.map{|c|"#{c.type}:#{c.id}"}.join(", ")
					@entities.delete entity.id
					@components_by_entity.delete entity.id
				# else
				# 	log @components_by_entity[entity.id].to_a.map{|e|e.join ":"}.join(", ")
				end
				@components.delete [entity, component.cla, component.id]
				@components.delete_if do |cla, comps|
					if Class === cla && Set === comps
						comps.delete_if do |e|
							ientity, icomponent = *e
							if ientity.id == entity.id && icomponent.type == component.type && icomponent.id == component.id
								# log :deleting, ientity.id, icomponent.type, icomponent.id, :from, id
								true
							else
								false
							end
						end
						comps.empty?
					elsif cla == [entity.id, component.cla, component.id]
						true
					elsif Array === cla && cla[0] == :all && cla[1] == entity.id
						true
					else
						false
					end
				end
				# log :handling, :remove, entity.id, component.type, component.id, :from, id
				handle_remove entity, component
			end
			entity
		end

		def inspect
			str = "#<Process:#{id}"
			str += " <= [#{after.map(&:id).join ", "}]" if after && after.length > 0
			str += " => [#{before.map(&:id).join ", "}]" if before && before.length > 0
			str += ">"
		end

		private
		def handle_add entity; end
		def handle_remove entity; end
	end
end