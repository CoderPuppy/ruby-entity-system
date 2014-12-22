module EntitySystem
	class Process
		attr_accessor :paused
		attr_reader :entities, :components, :components_by_entity

		def initialize game
			@game = game
			@paused = false
			@entities = {}
			@components = Hash.new do |h, k|
				if Class === k
					h[k] = Set.new
				elsif Array === k && k.length == 2
					h[k + [:main]]
				elsif Array === k && k.length == 3 && k[0] == :all
					h[k] = Set.new
				elsif Fixnum === k
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
				return unless component.enabled?
				entity = @entities[entity.id] || entity
				component = @components[[entity.id, component.cla, component.id]] || component
				# log :trying, :to, :add, entity.id, component.type, component.id, :to, self.id
				return entity unless handles? entity, component
				unless @components[[entity.id, component.cla, component.id]]
					# log :adding, entity.id, component.type, component.id, :to, self.id
					@entities[entity.id] = entity
					@components[entity.id] << [component.type, component.id]
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
				return raw_entity unless entity
				component = @components[[entity.id, raw_component.cla, raw_component.id]]
				return raw_entity unless component
				# log :removing, entity.id, component.type, component.id, :from, id
				e = @entities[entity.id]
				@components[entity.id].delete [component.type, component.id]
				if @components[entity.id].empty?
					@entities.delete entity.id
					@components.delete entity.id
				end
				@components.delete [entity, component.cla, component.id]
				@components.delete_if do |cla, comps|
					if Class === cla && Set === comps
						comps.delete_if do |e|
							ientity, icomponent = *e
							if ientity.id == entity.id && icomponent.type == component.type && icomponent.id == component.id
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