module EntitySystem
	Component::PhysicsCollision = Component.new
	class Process::PhysicsCollision < Process
		def after;[ Component::Velocity ];end

		def handles? entity
			entity[Component::PhysicsCollision]
		end

		def tick
			sections = {}
			@entities.each do |entity|
				prev_pos = entity[Component::Position].prev
				next_pos = entity[Component::Position].next

				prev_box = entity[Component::BoundingBox].prev
				next_box = entity[Component::BoundingBox].next

				prev_offset_box = prev_box.offset prev_pos
				next_offset_box = next_box.offset next_pos

				x = [prev_offset_box.x1, next_offset_box.x1].min
				y = [prev_offset_box.y1, next_offset_box.y1].min
				box = Component::BoundingBox[
					x, y,
					[prev_offset_box.x2, next_offset_box.x2].max - x,
					[prev_offset_box.y2, next_offset_box.y2].max - y
				]

				(box.sections(:A) + box.sections(:B)).each do |key|
					sections[key] ||= Set.new
					sections[key] << [entity, box]
				end
			end

			# ap sections

			calc_speed = ->(axis, e) {
				e[Component::Position].next.public_send(axis) - e[Component::Position].prev.public_send(axis)
			}

			calc_time = ->(axis, e_a, b_a, e_b, b_b) {
				b_a, b_b = b_a.offset(e_a[Component::Position].prev), b_b.offset(e_b[Component::Position].prev)
				s_a = calc_speed[axis, e_a]
				s_b = calc_speed[axis, e_b]
				# if b_b.public_send("#{axis}2") < b_a.public_send("#{axis}1")
				if b_a.public_send("#{axis}2") >= b_b.public_send("#{axis}1") && b_b.public_send("#{axis}2") < b_a.public_send("#{axis}1")
					# puts "swap"
					# ap({
					# 	axis: axis,
					# 	b_a: b_a.public_send(axis),
					# 	w_a: b_a.public_send("#{axis}2") - b_a.public_send(axis),
					# 	"b_a + w_a" => b_a.public_send("#{axis}2"),
					# 	b_b: b_b.public_send(axis)
					# })
					e_a, e_b = e_b, e_a
					b_a, b_b = b_b, b_a
					s_a, s_b = s_b, s_a
				end
				ds = s_a - s_b
				dist = b_a.public_send("#{axis}2") - b_b.public_send("#{axis}1")
				return Float::INFINITY if ds == 0
				t = -dist / ds
				# ap({
				# 	e_a: e_a,
				# 	e_b: e_b,
				# 	axis: axis,
				# 	s_a: s_a,
				# 	s_b: s_b,
				# 	dist: dist,
				# 	ds: ds,
				# 	b_a: b_a.public_send(axis),
				# 	b_b: b_b.public_send(axis),
				# 	w_a: b_a.public_send("#{axis}2") - b_a.public_send(axis),
				# 	w_b: b_b.public_send("#{axis}2") - b_b.public_send(axis),
				# 	b2_a: b_a.public_send("#{axis}2"),
				# 	b2_b: b_b.public_send("#{axis}2")
				# })
				t
			}

			stop_movement = ->(axis, e, t) {
				return if t > 1
				e[Component::Position].next.public_send "#{axis}=", e[Component::Position].prev.public_send(axis) + calc_speed[axis, e]*t
			}

			sections.each do |key, section|
				section.each do |entry_a|
					entity_a, box_a = *entry_a
					box_a = box_a.offset entity_a[Component::Position].next

					section.each do |entry_b|
						next if entry_a == entry_b
						entity_b, box_b = *entry_b
						box_b = box_b.offset entity_b[Component::Position].next

						# ap [entity_a, entity_b]

							begin
								t_x = calc_time[:x, entity_a, entity_a[Component::BoundingBox].next, entity_b, entity_b[Component::BoundingBox].next]
								stop_movement[:x, entity_a, t_x]
								stop_movement[:x, entity_b, t_x]
								
								t_y = calc_time[:y, entity_a, entity_a[Component::BoundingBox].next, entity_b, entity_b[Component::BoundingBox].next]
								stop_movement[:y, entity_a, t_y]
								stop_movement[:y, entity_b, t_y]

								if (t_x > 0 && t_x <= 1) || (t_y > 0 && t_y <= 1)
									# ap({
									# 	a: entity_a,
									# 	b: entity_b,
									# 	t_x: t_x,
									# 	t_y: t_y
									# })
								end
							end
						if box_a.intersects? box_b

							# entity_a[Component::Position].next = entity_a[Component::Position].prev
							# entity_b[Component::Position].next = entity_b[Component::Position].prev
							# puts "PhysicsCollision - #{entity_a.id.ai} and #{entity_b.id.ai} intersect"
						end
					end
				end
				# coll = entity[Component::Collision].next
			end
		end
	end
end