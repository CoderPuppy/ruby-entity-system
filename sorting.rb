require "set"

module Game
	Process = Struct.new :name, :after, :before do
		def inspect
			str = "#<Process:#{name}"
			str += " <= [#{after.join ", "}]" if after && after.length > 0
			str += " => [#{before.join ", "}]" if before && before.length > 0
			str += ">"
		end
	end

	def self.sort(processes)
		processes = Hash[processes.map { |process| [process.name, process] }]
		afters = {}
		processes.each do |name, process|
			afters[process.name] = [Set.new(process.after), [Set.new(process.after)]]
		end
		processes.each do |name, process|
			process.before.each do |before|
				afters[before].first << name
				afters[before].last.last << name
			end
		end
		while true
			any = false
			afters.each do |k, after|
				new_procs = Set.new
				after.last.last.each do |name|
					process = processes[name]
					unless process.after.empty?
						any = true
						new_procs.merge process.after
						if process.after.include? k
							raise "Cyclic Dependency between #{k} and #{process.name}"
						end
					end
				end
				after.first.merge new_procs
				after.last << new_procs
			end
			break unless any
		end
		# puts afters.map { |k, v| "#{k} <= #{v.first.to_a.join ", "}" }.join "\n"
		processes.map(&:last).sort do |a, b|
			a_after = afters[a.name].first
			b_after = afters[b.name].first
			# p a, a_after
			# p b, b_after
			if a_after.include? b.name
				1
			elsif b_after.include? a.name
				-1
			else
				0
			end
		end
	end

	res = sort([
		Process.new(:"input:opengl", [], []),
		Process.new(:"input:key", [:"input:opengl"], []),
		Process.new(:move, [], []),
		Process.new(:"input:move", [:"input:key", :"input:mouse"], [:move]),
		Process.new(:"input:mouse", [:"input:opengl"], []),
		Process.new(:friction, [], [:move]),
		Process.new(:ai, [], [:move])
	])

	# puts "-" * 100
	puts res.map(&:inspect).join("\n")
end