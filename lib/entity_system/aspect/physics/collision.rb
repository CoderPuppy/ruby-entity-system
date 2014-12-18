module EntitySystem
	Component::PhysicsCollision = Component.new box_id: :main
	class Process::PhysicsCollision < Process
		def after;[ Component::Velocity ];end

		def handles? entity, component
			case [component.type, true]
			when [Component::Position.id, component.id == :main]
				true
			when [Component::Area.id, component.id == :main]
				true
			when [Component::PhysicsCollision.id, true]
				true
			when [Component::BoundingBox.id, true]
				true
			else
				false
			end
		end

		def tick
			sections = {}
			@components[Component::PhysicsCollision].each do |e|
				entity, coll = *e
				pos = @components[[entity.id, Component::Position]]
				next unless pos
				prev_pos = pos.prev
				next_pos = pos.next

				coll = coll.next
				box = @components[[entity.id, Component::BoundingBox, coll.box_id]]
				next unless box
				prev_box = box.prev
				next_box = box.next

				prev_offset_box = prev_box.offset prev_pos
				next_offset_box = next_box.offset next_pos

				x = [prev_offset_box.x1, next_offset_box.x1].min
				y = [prev_offset_box.y1, next_offset_box.y1].min
				box = Component::BoundingBox[
					x, y,
					[prev_offset_box.x2, next_offset_box.x2].max - x,
					[prev_offset_box.y2, next_offset_box.y2].max - y
				]

				# log entity.id
				# box.sections(:A).each do |key|
					# log entity.id, key
					key = :all
					key = [@components[[entity.id, Component::Area]].next.area, key]
					sections[key] ||= Set.new

					# if entity.id == 0
					# 	log next_pos.inspect
					# 	log next_box.inspect
					# 	log next_offset_box.inspect
					# end
					sections[key] << [entity, coll.box_id, prev_offset_box, box]
				# end
			end
			# log sections

			def calc_speed axis, e
				@components[[e.id, Component::Position]].next.public_send(axis) - @components[[e.id, Component::Position]].prev.public_send(axis)
			end

			def calc_time axis, e_a, b_a, e_b, b_b
				s_a = calc_speed axis, e_a
				s_b = calc_speed axis, e_b
				if b_a.public_send("#{axis}2") > b_b.public_send("#{axis}1") && b_b.public_send("#{axis}2") <= b_a.public_send("#{axis}1")
					# log :swap, e_a.id, e_b.id
					# log b_a.to_s, b_b.to_s
					e_a, e_b = e_b, e_a
					b_a, b_b = b_b, b_a
					s_a, s_b = s_b, s_a
				end
				ds = s_b - s_a
				return Float::INFINITY if ds >= 0
				dist = b_a.public_send("#{axis}2") - b_b.public_send("#{axis}1")
				# log({
				# 	axis: axis,
				# 	dist: dist,
				# 	ds: ds,
				# 	e_a: e_a.id,
				# 	e_b: e_b.id,
				# 	b_a: {
				# 		x1: b_a.x1,
				# 		x2: b_a.x2,
				# 		y1: b_a.y1,
				# 		y2: b_a.y2,
				# 		width: b_a.width,
				# 		height: b_a.height
				# 	},
				# 	b_b: {
				# 		x1: b_b.x1,
				# 		x2: b_b.x2,
				# 		y1: b_b.y1,
				# 		y2: b_b.y2,
				# 		width: b_b.width,
				# 		height: b_b.height
				# 	},
				# 	s_a: s_a,
				# 	s_b: s_b
				# })
				dist.to_f / ds.to_f
			end

			def valid_time? t
				t < 1 && t >= 0
			end

			def stop_movement axis, e, t
				return if t == Float::INFINITY
				# log :t, t
				# if e[Component::Velocity]
				# 	log e[Component::Velocity].prev.to_s, e[Component::Velocity].next.to_s
				# end
				return unless valid_time? t
				speed = calc_speed axis, e
				pos = @components[[e.id, Component::Position]]
				# log({
				# 	axis: axis,
				# 	t: t,
				# 	speed: speed,
				# 	move: speed*t,
				# 	next: pos.next.public_send(axis),
				# 	prev: pos.prev.public_send(axis),
				# 	new: pos.prev.public_send(axis) + speed*t
				# })
				pos.next.public_send "#{axis}=", pos.prev.public_send(axis) + speed*t
			end

			handled = Set.new
			sections.each do |key, section|
				section.each do |entry_a|
					entity_a, id_a, box_a, big_box_a = *entry_a

					section.each do |entry_b|
						next if entry_a == entry_b
						entity_b, id_b, box_b, big_box_b = *entry_b
						key = [[entity_a.id, id_a], [entity_b.id, id_b]].sort!
						next if handled.include? key
						handled << key

						intersects = big_box_a.intersects? big_box_b
						# log :intersects, entity_a.id, entity_b.id if intersects

						if intersects
							t_x = calc_time :x, entity_a, box_a, entity_b, box_b
							stop_movement :x, entity_a, t_x
							stop_movement :x, entity_b, t_x
							
							t_y = calc_time :y, entity_a, box_a, entity_b, box_b
							stop_movement :y, entity_a, t_y
							stop_movement :y, entity_b, t_y
						end
					end
				end
			end
		end
	end
end