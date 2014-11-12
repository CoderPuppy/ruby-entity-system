module EntitySystem
	Component::BoundingBox = Component.new :x, :y, :width, :height do
		define_method :x1 do; x          ;end
		define_method :x2 do; x + width  ;end
		
		define_method :y1 do; y          ;end
		define_method :y2 do; y + height ;end

		define_method :intersects? do |ix, iy = nil|
			if iy == nil
				ix.x1 <= x2 && ix.x2 >= x1 &&
				ix.y1 <= y2 && ix.y2 >= y1
			else
				ix >= x1 && ix <= x2 &&
				iy >= y1 && iy <= y2
			end
		end

		define_method :touching? do |ix, iy = nil|
			if iy == nil
				x_intersect = ix.x1 <= x2 && ix.x2 >= x1
				y_intersect = ix.y1 <= y2 && ix.y2 >= y1
				return if intersects?(ix)
				return :top if x_intersect && ix.y2 == y1 - 1
				return :bottom if x_intersect && ix.y1 == y2 + 1
				return :left if y_intersect && ix.x2 == x1 - 1
				return :right if y_intersect && ix.x1 == x2 + 1
			else
				x_intersect = ix >= x1 - 1 && ix <= x2 + 1
				y_intersect = iy >= y1 - 1 && iy <= y2 + 1
				(x_intersect && iy == y2 + 1) ||
				(x_intersect && iy == y1 - 1) ||
				(y_intersect && ix == x2 + 1) ||
				(y_intersect && ix == x1 - 1)
			end
		end

		define_method :offset do |ox, oy = nil|
			if oy == nil
				offset ox.x, ox.y
			else
				Component::BoundingBox[x + ox, y + oy, width, height]
			end
		end
	end
end