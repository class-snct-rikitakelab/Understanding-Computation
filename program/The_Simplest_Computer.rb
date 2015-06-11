##CHAPTER 3
##The Simplest Computers

##Deterministic Finite Automata

class FARule < Struct.new(:state, :character, :next_state)
	def applies_to?(state, character)
		self.state == state && self.character == character
	end
	
	def follow
		next_state
	end
	
	def inspect
		"#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}>"
	end
end

class DFARulebook < Struct.new(:rules)
	def next_state(state, character)
 		rule_for(state, character).follow
	end

	def rule_for(state, character)
		rules.detect { |rule| rule.applies_to?(state, character) }
	end
end

#>> rulebook = DFARulebook.new([
# FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
# FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
# FARule.new(3, 'a', 3), FARule.new(3, 'b', 3)
# ])
#=> #<struct DFARulebook …>
#>> rulebook.next_state(1, 'a')
#=> 2
#>> rulebook.next_state(1, 'b')
#=> 1
#>> rulebook.next_state(2, 'b')
#=> 3

class DFA < Struct.new(:current_state, :accept_states, :rulebook)
	def accepting?
		accept_states.include?(current_state)
	end

	def read_character(character)
		self.current_state = rulebook.next_state(current_state, character)
	end

	def read_string(string)
		string.chars.each do |character|
			read_character(character)
		end
	end

	def to_dfa
		DFA.new(start_state, accept_states, rulebook)
	end
	
	def accepts?(string)
		to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
	end


end

#>> DFA.new(1, [1, 3], rulebook).accepting?
#=> true
#>> DFA.new(1, [3], rulebook).accepting?
#=> false

#>> dfa = DFA.new(1, [3], rulebook); dfa.accepting?
#=> false
#>> dfa.read_character('b'); dfa.accepting?
#=> false
#>> 3.times do dfa.read_character('a') end; dfa.accepting?
#=> false
#>> dfa.read_character('b'); dfa.accepting?
#=> true

#>> dfa = DFA.new(1, [3], rulebook); dfa.accepting?
#=> false
#>> dfa.read_string('baaab'); dfa.accepting?
#=> true

#>> dfa_design = DFADesign.new(1, [3], rulebook)
#=> #<struct DFADesign …>
#>> dfa_design.accepts?('a')
#=> false
#>> dfa_design.accepts?('baa')
#=> false
#>> dfa_design.accepts?('baba')
#=> true