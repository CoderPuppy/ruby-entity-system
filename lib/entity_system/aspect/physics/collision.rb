module EntitySystem
	Component::Collision = Component.new :colliding
	class Process::Collision < Process
		SECTION_SIZE = 30

		def handles? entity
			entity[Component::Position] && entity[Component::BoundingBox] && entity[Component::Collision]
		end

		def tick
			sections = {}
			@entities.each do |entity|
				pos = entity[Component::Position]
				vel = entity[Component::Velocity]
				box = entity[Component::BoundingBox].next
				coll = entity[Component::Collision]

				pos_prev = pos.prev
				pos_next = pos.next

				base_x = pos_next.x + box.x
				base_y = pos_next.y + box.y

				offset_x = 0
				offset_y = 0
				base_offset = 0

				log = ->() {
					next_bound_x = ((base_x + offset_x).abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE - base_x.abs - offset_x
					next_bound_y = ((base_y + offset_y).abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE - base_y.abs - offset_y
					ap({
						axis: base_offset == 0 ? :A : :B,
						pos: "#{base_x} #{base_y}",
						offset: "#{offset_x} #{offset_y}",
						size: "#{box.width} #{box.height}",
						next_bound: "#{next_bound_x} #{next_bound_y}"
					})
				}

				while base_offset <= SECTION_SIZE/2
					loop do
						loop do
							log[]
							raw_x = base_x + offset_x + base_offset
							raw_y = base_x + offset_y + base_offset

							x = ((raw_x.abs - (raw_x.abs % SECTION_SIZE)) / SECTION_SIZE).to_i
							if raw_x < 0
								x *= -1
								x -= 1
							end

							y = ((raw_y.abs - (raw_y.abs % SECTION_SIZE)) / SECTION_SIZE).to_i
							if raw_y < 0
								y *= -1
								y -= 1
							end

							full = "#{base_offset == 0 ? "A" : "B"}#{x},#{y}"

							sections[full] ||= Set.new
							sections[full] << [entity, box, [base_x + offset_x, pos_next.y + box.y + offset_y]]

							ap full

							# ap({
							# 	name: base_offset == 0 ? :A : :B,
							# 	entity: entity.id,
							# 	box: box,
							# 	pos: pos_next,
							# 	offset: "#{offset_x} #{offset_y}",
							# 	raw: "#{raw_x} #{raw_y}",
							# 	real: "#{x} #{y}"
							# })

							next_bound_y = ((base_y + offset_y).abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE - base_y.abs - offset_y
							break if next_bound_y <= 0
							offset_y += SECTION_SIZE
						end
						offset_y = 0
						next_bound_x = ((base_x + offset_x).abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE - base_x.abs - offset_x
						break if next_bound_x <= 0
						offset_x += SECTION_SIZE
					end
					offset_x = 0
					base_offset += SECTION_SIZE/2
				end
			end
			# ap sections
		end
	end
end