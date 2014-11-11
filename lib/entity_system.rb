require "set"
require "awesome_print"

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
end

require File.expand_path("../entity_system/game.rb", __FILE__)
require File.expand_path("../entity_system/entity.rb", __FILE__)
require File.expand_path("../entity_system/process.rb", __FILE__)
require File.expand_path("../entity_system/component.rb", __FILE__)
require File.expand_path("../entity_system/store.rb", __FILE__)
require File.expand_path("../entity_system/game_store.rb", __FILE__)

# Stores
require File.expand_path("../entity_system/store/memory.rb", __FILE__)
require File.expand_path("../entity_system/store/cached.rb", __FILE__)

# Aspects
require File.expand_path("../entity_system/aspect/identity.rb", __FILE__)
require File.expand_path("../entity_system/aspect/debug_name.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/area.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/position.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/velocity.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/bounding_box.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/collision.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/friction.rb", __FILE__)
require File.expand_path("../entity_system/aspect/physics/gravity.rb", __FILE__)
require File.expand_path("../entity_system/aspect/rendering/tracked.rb", __FILE__)