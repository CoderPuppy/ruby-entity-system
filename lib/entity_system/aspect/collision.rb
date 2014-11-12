module EntitySystem
	Component::Collision = Component.new :touching_top, :touching_bottom, :touching_left, :touching_right, :intersecting do
		define_method :initialize do
			super Set.new, Set.new, Set.new, Set.new, Set.new
		end
	end
	class Process::Collision < Process
		SECTION_SIZE = 30

		def after; [Process::Velocity]; end

		def handles? entity
			entity[Component::Collision] && entity[Component::Position] && entity[Component::BoundingBox]
		end

		def tick
			sections = {}
			@entities.each do |entity|
				pos = entity[Component::Position].next
				box = entity[Component::BoundingBox].next

				base_offset = 0

				base_x = pos.x + box.x
				base_y = pos.y + box.y

				offset_x = 0
				offset_y = 0

				while base_offset < SECTION_SIZE
					alignment = base_offset == 0 ? :A : :B

					tmp_offset_x = 0
					curr_x = ->() { base_x + offset_x + base_offset + tmp_offset_x }
					if curr_x[] < 0
						tmp_offset_x += ((curr_x[].abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE).to_i
					end

					loop do
						next_bound_x = ((curr_x[].abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE).to_i - tmp_offset_x - base_offset
						far_bound_x = base_x + box.width

						tmp_offset_y = 0
						curr_y = ->() { base_y + offset_y + base_offset + tmp_offset_y }
						if curr_y[] < 0
							tmp_offset_y += ((curr_y[].abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE).to_i
						end
						
						loop do
							next_bound_y = ((curr_y[].abs.to_f/SECTION_SIZE).ceil * SECTION_SIZE).to_i - tmp_offset_y - base_offset
							far_bound_y = base_y + box.height
							
							x = ((curr_x[].abs - (curr_x[].abs % SECTION_SIZE)) / SECTION_SIZE).to_i
							if curr_x[] < 0
								x *= -1
								x -= 1
							end

							y = ((curr_y[].abs - (curr_y[].abs % SECTION_SIZE)) / SECTION_SIZE).to_i
							if curr_y[] < 0
								y *= -1
								y -= 1
							end

							key = "#{alignment}#{x},#{y}"
							# puts "#{entity.id} = #{key}"
							sections[key] ||= Set.new
							sections[key] << [entity, box]

							break if next_bound_y > far_bound_y
							offset_y += SECTION_SIZE
						end
						offset_y = 0

						break if next_bound_x > far_bound_x
						offset_x += SECTION_SIZE
					end

					base_offset += SECTION_SIZE/2
				end
			end

			sections.each do |key, section|
				section.each do |entry_a|
					entity_a, box_a = *entry_a
					box_a = box_a.offset entity_a[Component::Position].next
					coll_a = entity_a[Component::Collision].next

					section.each do |entry_b|
						next if entry_a == entry_b
						entity_b, box_b = *entry_b
						box_b = box_b.offset entity_b[Component::Position].next
						coll_b = entity_b[Component::Collision].next

						if box_a.intersects? box_b
							puts "#{entity_a.id} and #{entity_b.id} intersect"
							coll_a.intersecting += [entity_b.id]
							coll_b.intersecting += [entity_a.id]
						end

						touching = box_a.touching? box_b
						if touching
							# puts "#{entity_b.id} is touching #{entity_a.id} on the #{touching}"
							coll_b.public_send("touching_#{touching}=", coll_b.public_send("touching_#{touching}") + [entity_a.id])
						end
					end
				end
				# coll = entity[Component::Collision].next
			end
		end
	end
end