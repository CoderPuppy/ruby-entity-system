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
				offset_box = box.offset pos

				(offset_box.sections(:A) + offset_box.sections(:B)).each do |key|
					sections[key] ||= Set.new
					sections[key] << [entity, box]
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