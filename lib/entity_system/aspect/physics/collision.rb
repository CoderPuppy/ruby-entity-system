module EntitySystem
	Component::PhysicsCollision = Component.new
	class Process::PhysicsCollision < Process
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

			sections.each do |key, section|
				section.each do |entry_a|
					entity_a, box_a = *entry_a
					box_a = box_a.offset entity_a[Component::Position].next

					section.each do |entry_b|
						next if entry_a == entry_b
						entity_b, box_b = *entry_b
						box_b = box_b.offset entity_b[Component::Position].next

						if box_a.intersects? box_b
							entity_a[Component::Position].next = entity_a[Component::Position].prev
							entity_b[Component::Position].next = entity_b[Component::Position].prev
							puts "PhysicsCollision - #{entity_a.id.ai} and #{entity_b.id.ai} intersect"
						end
					end
				end
				# coll = entity[Component::Collision].next
			end
		end
	end
end