#　決定性プッシュダウンオートマトンのシミュレーション

require "./Equivalence.rb" 

class Stack < Struct.new(:contents)
	def push(character)
		Stack.new([character] + contents)
	end

	def pop
		Stack.new(contents.drop(1))
	end

	def top
		contents.first
	end

	def inspect
		"#<Stack {#{top}}#{contents.drop(1).join}>"
	end
end



#TEST1

stack = Stack.new(['a', 'b', 'c', 'd', 'e'])
# #<Stack (a)bcde>

stack.top
# "a"

stack.pop.pop.top
# "c"

stack.push('x').push('y').top
# "y"

stack.push('x').push('y').pop.top
# "x"



class PDAConfiguration < Struct.new(:state, :stack)
end

class PDARule < Struct.new(:state, :character, 
	:next_state, :pop_character, :push_characters)

	def applies_to?(configuration, character)
		self.state == configuration.state &&
		self.pop_character == configuration.stack.top &&
		self.character == character	
	end
end



# TEST2

rule = PDARule.new(1, '(', 2, '$', ['b', '$'])
# #<struct PDARule ・・・>

configuration = PDAConfiguration.new(1, Stack.new(['$']))
# #<struct PDAconfiguration ・・・　>

rule.applies_to?(configuration, '(')
# true

class PDARule
	def follow(configuration)
		PDAConfiguration.new(next_state, next_stack(configuration))
	end

	def next_stack(configuration)
		popped_stack = configuration.stack.pop

		push_characters.reverse.
			inject(popped_stack) { |stack, character| stack.push(character) }
	end
end



#TEST3
stack = Stack.new(['$']).push('x').push('y').push('z')
# #<Stack (z)yx$>

stack.top
# "z"

stack = stack.pop; stack.pop
# "y" 

stack = stack.pop; stack.top
# "x"

rule.follow(configuration)
# #<struct PDAConfiguration state=2, stack=#<Stack (b)$>>



class DPDARulebook < Struct.new(:rules)
	def next_configuration(configuration, character)
		rule_for(configuration, character).follow(configuration)
	end

	def rule_for(configuration, character)
		rules.detect { |rule| rule.applies_to?(configuration)}
	end
end


# TEST4
rulebook = DPDARulebook.new([
	PDARule.new(1, '(', 2, '$', ['b', '$']),
	PDARule.new(2, '(', 2, 'b', ['b', 'b']),
	PDARule.new(2, ')', 2, 'b', []),
	PDARule.new(2, nil, 1, '$', ['$']),
	])
# #struct DPDARulebook rules=[...]

configuration = rulebook.next_configuration(configuration, '(')
# #<struct PDAConfiguration state=2, stack=#<Stack (b)$>>

configuration = rulebook.next_configuration(configuration, '(')
# #<struct PDAConfiguration state=2, stack=#<Stack (b)$>>

configuration = rulebook.next_configuration(configuration, ')')
# #<struct PDAConfiguration state=2, stack=#<Stack (b)$>>



class DPDA < Struct.new(:current_configuration, :accept_states, :rulebook)
	def accepting?
		accept_states.include?(current_configuration.state)
	end

	def read_character(character)
		self.current_configuration = 
			rulebook.next_configuration(current_configuration, character)
	end

	def read_string(string)
		string.chars.each do |character|
			read_character(character)
		end
	end
end



# TEST 5
dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
# #<struct DPDA ...>

dpda.accepting?
# true

dpda.read_string('(()'); dpda.accepting?
# false

data.current_configuration
# #<struct PDAConfiguration state=2, stack=#<Stack (b)$>>



class DPDARulebook
	def applies_to?(configuration, character)
		!rule_for(configuration, character).nil?
	end

	def follow_free_moves(configuration)
		if applies_to?(configuration, nil)
			follow_free_moves(next_configuration(configuration, nil))
		else
			configuration
		end
	end
end



# TEST6
configuration = PDAConfiguration.new(2, Stack.new(['$']))
# #<struct PDAConfiguration state=2, stack=#<Stack ($)>>

rulebook.follow_free_moves(configuration)
# #<struct PDAConfiguration state=1, stack=#<Stack ($)>>