module EntitySystem
	Component::BoundingBox = Component.new :x, :y, :width, :height do
		def self.singular; false; end

		SECTION_SIZE = 30

		def x1; x          ;end
		def x2; x + width  ;end
		
		def y1; y          ;end
		def y2; y + height ;end

		def intersects? ix, iy = nil
			if iy == nil
				ix.x1 < x2 && ix.x2 > x1 &&
				ix.y1 < y2 && ix.y2 > y1
			else
				ix > x1 && ix < x2 &&
				iy > y1 && iy < y2
			end
		end

		def touching? ix, iy = nil
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

		def offset ox, oy = nil
			if oy == nil
				offset ox.x, ox.y
			else
				Component::BoundingBox[x + ox, y + oy, width, height]
			end
		end

		def sections alignment
			base_offset = case alignment
			when :A
				0
			when :B
				SECTION_SIZE/2
			end

			sections = Set.new

			offset_x = 0
			tmp_offset_x = 0
			curr_x = ->() { x + offset_x + base_offset + tmp_offset_x }
			if curr_x[] < 0
				tmp_offset_x += ((curr_x[].abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE).to_i
			end

			loop do
				next_bound_x = ((curr_x[].abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE).to_i - tmp_offset_x - base_offset
				far_bound_x = x + width

				offset_y = 0
				tmp_offset_y = 0
				curr_y = ->() { y + offset_y + base_offset + tmp_offset_y }
				if curr_y[] < 0
					tmp_offset_y += ((curr_y[].abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE).to_i
				end
				
				loop do
					next_bound_y = ((curr_y[].abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE).to_i - tmp_offset_y - base_offset
					far_bound_y = y + height
					
					x = ((curr_x[].abs - (curr_x[].abs % SECTION_SIZE)) / SECTION_SIZE).to_i - tmp_offset_x/SECTION_SIZE
					# if curr_x[] < 0
					# 	x *= -1
					# 	x -= 1
					# end

					y = ((curr_y[].abs - (curr_y[].abs % SECTION_SIZE)) / SECTION_SIZE).to_i - tmp_offset_y/SECTION_SIZE
					# if curr_y[] < 0
					# 	y *= -1
					# 	y -= 1
					# end

					# ap({
					# 	alignment: alignment,
					# 	real_x: self.x,
					# 	curr_x: curr_x[],
					# 	x: x,
					# 	tmp_offset_x: tmp_offset_x,
					# 	real_y: self.y,
					# 	curr_y: curr_y[],
					# 	y: y,
					# 	tmp_offset_y: tmp_offset_y
					# })

					key = "#{alignment}#{x},#{y}"
					sections << key

					break if next_bound_y > far_bound_y
					offset_y += SECTION_SIZE
				end
				offset_y = 0

				break if next_bound_x > far_bound_x
				offset_x += SECTION_SIZE
			end

			sections
		end
	end
end