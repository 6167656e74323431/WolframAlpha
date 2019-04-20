# module to encapulate table formatting methods
module TableFormatting
	#checks if it is needed to be a table format
	def toTableIfNecessary
		return self.toTable if self.include? " |"
		return self
	end

	# converts to a table format
	def toTable
		table = self.split "\n"
		(0...table.length).each do |i|
			table[i] = table[i].split(" |").map(&:strip).delete_if {|cell| cell == ""}
		end

		appendixes = []
		table.each do |row|
			appendixes << row[0] if row.length == 1 and row[0][0] == "(" and row[0][-1] == ")"
		end
		table = table.delete_if {|row| row.length == 1 and row[0][0] == "(" and row[0][-1] == ")"}
		
		max_row_number = 0
		table.each do |row|
			max_row_number = [max_row_number, row.length].max
		end

		table.each do |row|
			while row.length < max_row_number do 
				row << ""
			end
		end

		(0...(max_row_number - 1)).each do |row_number|
			max_length = 0
			table.each do |row|
				max_length = [max_length, row[row_number].length].max
			end

			table.each do |row|
				row[row_number] += (" " * (max_length - row[row_number].length))
			end
		end

		(0...table.length).each do |i|
			table[i] = table[i].join "  "
		end

		return "```\n#{table.join "\n"}\n#{appendixes.join "\n"}\n```"
	end
end

# add fromatting to string class
class String
	include TableFormatting
end
