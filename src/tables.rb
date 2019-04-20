require_relative 'logging.rb'

# module to encapulate table formatting methods
module TableFormatting
	#checks if it is needed to be a table format
	# logging id: 8
	def toTableIfNecessary
		Logging.log("Table Conversion", "Conversion", "Deemed Necessary", 8) if self.include? " |"
		return self.toTable if self.include? " |"
		Logging.log("Table Conversion", "Conversion", "Deemed Not Necessary", 8)
		return self
	end

	# converts to a table format
	# logging id: 9
	def toTable
		table = self.split "\n"
		(0...table.length).each do |i|
			table[i] = table[i].split(" |").map(&:strip).delete_if {|cell| cell == ""}
		end
		Logging.log("Table Conversion", "Processing", "Split Into Cells", 9)

		appendixes = []
		table.each do |row|
			appendixes << row[0] if row.length == 1 and ((row[0][0] == "(" and row[0][-1] == ")") or row[0][0] == "*")
		end
		table = table.delete_if {|row| row.length == 1 and ((row[0][0] == "(" and row[0][-1] == ")") or row[0][0] == "*")}
		Logging.log("Table Conversion", "Processing", "Removed appendixes", 9)
		
		max_row_number = 0
		table.each do |row|
			max_row_number = [max_row_number, row.length].max
		end
		Logging.log("Table Conversion", "Processing", "Faound Max Table Length", 9)

		table.each do |row|
			while row.length < max_row_number do 
				row << ""
			end
		end
		Logging.log("Table Conversion", "Processing", "Rectangled the Table", 9)

		(0...(max_row_number - 1)).each do |row_number|
			max_length = 0
			table.each do |row|
				max_length = [max_length, row[row_number].length].max
			end
			Logging.log("Table Conversion", "Processing", "Foud Longest Cell in row #{row_number + 1}/#{max_row_number - 1}", 9)

			table.each do |row|
				row[row_number] += (" " * (max_length - row[row_number].length))
			end
			Logging.log("Table Conversion", "Processing", "Added Spacing to Row #{row_number + 1}/#{max_row_number - 1}", 9)
		end

		(0...table.length).each do |i|
			table[i] = table[i].join "  "
		end

		Logging.log("Table Conversion", "Processing", "Rejoined Table and appendixes", 9)
		return "```\n#{table.join "\n"}\n```#{appendixes.join "\n"}"
	end
end

# add fromatting to string class
class String
	include TableFormatting
end
