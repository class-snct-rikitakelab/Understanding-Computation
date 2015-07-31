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
		"#<Stack (#{top})#{contents.drop(1).join}>"
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
		rules.detect { |rule| rule.applies_to?(configuration, character)}
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

dpda.current_configuration
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

DPDARulebook.new([PDARule.new(1, nil, 1, '$', ['$'])]).
	follow_free_moves(PDAConfiguration.new(1, Stack.new(['$'])))
# SystemStackError: stack level too deep



class DPDA
	def current_configuration
		rulebook.follow_free_moves(super)
	end
end


# TEST 7
dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
# #<struct DPDA ...>

dpda.read_string('(()('); dpda.accepting?
# false

dpda.current_configuration
# #<struct PDAConfiguration state=2, stack=#<Stack (b)b$>>

dpda.read_string('))()'); dpda.accepting?
# true

dpda.current_configuration
# #<struct PDAConfiguration state=1, stack=#<Stack ($)>>



class DPDADesign < Struct.new(:start_state, :bottom_character,
							:accept_states, :rulebook)
	def accepts?(string)
		to_dpda.tap { |dpda| dpda.read_string(string) }.accepting?
	end

	def to_dpda
		start_stack = Stack.new([bottom_character])
		start_configuration = PDAConfiguration.new(start_state, start_stack)
		DPDA.new(start_configuration, accept_states, rulebook)
	end
end



# TEST 8

dpda_design = DPDADesign.new(1, '$', [1], rulebook)
# #<struct DPDADesign ...>

dpda_design.accepts?('(((((((((())))))))))')
# true

dpda_design.accepts?('()(())((()))(()(()))')
# true

dpda_design.accepts?('(()(()(()()(()()))()')
# false

dpda_design.accepts?('(()')
# NoMethodError: ...



class PDAConfiguration
	STUCK_STATE = Object.new

	def stuck
		PDAConfiguration.new(STUCK_STATE, stack)
	end

	def stuck?
		state == STUCK_STATE
	end
end

class DPDA
	def next_configuration(character)
		if rulebook.applies_to?(current_configuration, bottom_character)
			rulebook.next_configuration(current_configuration, character)
		else
			current_configuration.stuck
		end
	end

	def stuck?
		current_configuration.stuck?
	end

	def read_character(character)
		self.current_configuration = next_configuration(character)
	end

	def read_string(string)
		string.chars.each do |character|
			read_character(character) unless stuck?
		end
	end
end



#TEST 9
dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
# #<struct DPDA ...>

dpda.read_string('())'); dpda.current_configuration
# #<struct PDAConfiguration state=#<Object>, stack=#<Stack ($)>>

dpda.accepting?
# false

dpda.stuck?
# true

dpda_design.accepts?('())')
# false