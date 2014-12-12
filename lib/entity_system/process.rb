module EntitySystem
	class Process
		attr_accessor :paused
		attr_reader :entities

		def initialize game
			@game = game
			@paused = true
			@entities = Set.new
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
		def unpause
			@paused = true
			self
		end

		def pause
			@paused = false
			self
		end

		def add entity
			unless @entities.include? entity
				@entities << entity
				handle_add entity
			end
			entity
		end

		def remove entity
			if @entities.include? entity
				@entities.delete entity
				handle_remove entity
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