require "set"
# require "awesome_print"
require "json"

module EntitySystem
	class Box
		def initialize(val)
			@value = val
		end

		attr_accessor :value
		alias :get :value
		alias :set :value=

		def inspect
			"#<Box #{@value.inspect}>"
		end
	end

	class BorrowedPointer
		def initialize(obj, key)
			@object = obj
			@key = key
		end

		def value
			@object.get.send key
		end
		alias :get :value

		def value= val
			@object.get.send "#{key}=", val
		end
		alias :set :value=
	end

	Rect = Struct.new :x, :y, :width, :height do
		alias :w  :width
		alias :w= :width=
		alias :h  :height
		alias :h= :height=
	end

	if Kernel.const_defined? :AwesomePrint
		module AwesomePrint
			def self.included mod
				mod.send :alias_method, :cast_without_entity_system, :cast
				mod.send :alias_method, :cast, :cast_with_entity_system
			end

			def cast_with_entity_system object, type
				cast = cast_without_entity_system object, type
				if object.is_a? Component
					cast = :entity_system_component
				end
				cast
			end

			def awesome_entity_system_component object
				name = colorize object.class.name.split("::").last, :class
				data = object.to_h.map { |k, v| [k, @inspector.awesome(v)] }
				kv = ->(kv) { "#{kv.first}=#{kv.last}" }
				kv_spaced = ->(kv) { "#{kv.first} = #{kv.last}" }
				if object.length == 0
					name
				else
					# "#{name}(#{data.map(&kv).join(", ")})"
					"#<#{name} #{data.map(&kv).join(" ")}>"
				end
			end
		end
		::AwesomePrint::Formatter.send :include, AwesomePrint
	end
end

require File.expand_path("../store.rb", __FILE__)

require File.expand_path("../entity_system/game.rb", __FILE__)
require File.expand_path("../entity_system/entity.rb", __FILE__)
require File.expand_path("../entity_system/process.rb", __FILE__)
require File.expand_path("../entity_system/component.rb", __FILE__)
require File.expand_path("../entity_system/game_store.rb", __FILE__)

# Aspects
require File.expand_path("../entity_system/aspect/identity.rb", __FILE__)
require File.expand_path("../entity_system/aspect/debug_name.rb", __FILE__)
require File.expand_path("../entity_system/aspect/area.rb", __FILE__)
require File.expand_path("../entity_system/aspect/position.rb", __FILE__)
require File.expand_path("../entity_system/aspect/facing.rb", __FILE__)
require File.expand_path("../entity_system/aspect/bounding_box.rb", __FILE__)
require File.expand_path("../entity_system/aspect/collision.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/collision.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/velocity.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/friction.rb", __FILE__)
require File.expand_path("../entity_system/aspect/rendering/tracked.rb", __FILE__)