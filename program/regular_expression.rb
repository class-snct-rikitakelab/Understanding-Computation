#
# 正規表現のソースコード
#

# NFAのソースコードを取り込む
require "./The_Simplest_Computer.rb" 

module Pattern
	def bracket(outer_precedence)
		if precedence < outer_precedence
			'(' + to_s + ')'
		else
			to_s
		end
	end

	def inspect
		"/#{self}/"
	end
end

class Empty
	include Pattern

	def to_s
		''
	end

	def precedence
		3
	end
end

class Literal < Struct.new(:character)
	include Pattern

	def to_s
		character
	end

	def precedence
		3
	end
end

class Concatenate < Struct.new(:first, :second)
	include Pattern

	def to_s
		[first, second].map { |pattern| pattern.bracket(precedence) }.join
	end

	def precedence
		1
	end
end

class Choose < Struct.new(:first, :second)
	include Pattern

		def to_s
		[first, second].map { |pattern| pattern.bracket(precedence) }.join('|')
	end

	def precedence
		0
	end	
end

class Repeat < Struct.new(:pattern)
	include Pattern

	def to_s
		pattern.bracket(precedence) + '*'
	end

	def precedence
		2
	end
end

#
# TEST1 正規表現　を　抽象構文木　の時みたいに作れる！
#
pattern = Repeat.new(
	Choose.new(
		Concatenate.new( Literal.new('a'), Literal.new('b') ),
		Literal.new('a')
		)
	)
# RESULT1-1 # /(ab|a)*/



class Empty
	def to_nfa_design
		start_state = Object.new
		accept_states = [start_state]
		rulebook = NFARulebook.new([])

		NFADesign.new(start_state, accept_states, rulebook)
	end
end

class Literal
	def to_nfa_design
		start_state = Object.new
		accept_state = Object.new
		rule = FARule.new(start_state, character, accept_state)
		rulebook = NFARulebook.new([rule])

		NFADesign.new(start_state, [accept_state], rulebook)
	end	
end

#
# TEST2 正規表現　を　非決定性有限オートマトン　で表現する機能を持たせる
#

nfa_design = Empty.new.to_nfa_design
# TEST2-1 # #<struct NFADesign ・・・>

nfa_design.accepts?('')
# TEST2-2 # true

nfa_design.accepts?('a')
# TEST2-3 # false

nfa_design = Literal.new('a').to_nfa_design
# TEST2-4 # #<struct NFADesign ・・・>

nfa_design.accepts?('')
# TEST2-5 # false

nfa_design.accepts?('a')
# TEST2-6 # true

nfa_design.accepts?('b')
# TEST2-7 # false



module Pattern
	def matches?(string)
		to_nfa_design.accepts?(string)
	end
end

#
# TEST3　直接受理状態か確認できるようにする
#

Empty.new.matches?('a')
# TEST3-1 # false

Literal.new('a').matches?('a')
# TEST3-2 # true



class Concatenate
	def to_nfa_design
		first_nfa_design = first.to_nfa_design
		second_nfa_design = second.to_nfa_design

		start_state = first_nfa_design.start_state
		accept_states = second_nfa_design.accept_states
		rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
		extra_rules = first_nfa_design.accept_states.map { |state| 
			FARule.new(state, nil, second_nfa_design.start_state) 
		}
		rulebook = NFARulebook.new(rules + extra_rules)

		NFADesign.new(start_state, accept_states, rulebook)
	end
end

#
# TEST4 正規表現の「連接」を、非決定性有限オートマトンで表現
#

pattern = Concatenate.new( Literal.new('a'), Literal.new('b') )
# TEST4-1 # /ab/

pattern.matches?('a')
# TEST4-2 # false

pattern.matches?('ab')
# TEST4-3 # true

pattern.matches?('abc')
# TEST4-4 # false



#
# TEST5 2段階でConcatenateを使うこと（再帰）で、3つの状態を持つ非決定性有限オートマトンを作成
#

pattern = 
	Concatenate.new( 
		Literal.new('a'), 
		Concatenate.new( Literal.new('b'), Literal.new('c') )
	)
# TEST5-1 # /abc/

pattern.matches?('a')
# TEST5-2 # false

pattern.matches?('ab')
# TEST5-3 # false

pattern.matches?('abc')
# TEST5-4 # true



class Choose
	def to_nfa_design
		first_nfa_design = first.to_nfa_design
		second_nfa_design = second.to_nfa_design

		start_state = Object.new
		accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states
		rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
		extra_rules = [first_nfa_design, second_nfa_design].map { |nfa_design| 
			FARule.new(start_state, nil, nfa_design.start_state)
		}
		rulebook = NFARulebook.new(rules + extra_rules)

		NFADesign.new(start_state, accept_states, rulebook)
	end
end

#
# TEST6 正規表現の「｜(和)」を非決定性有限オートマトンで表現
#

pattern = Choose.new( Literal.new('a'), Literal.new('b') )
# TEST6-1 # /a|b/

pattern.matches?('a')
# TEST6-2 # true

pattern.matches?('b')
# TEST6-3 # true

pattern.matches?('c')
# TEST6-4 # false



class Repeat
	def to_nfa_design
		pattern_nfa_design = pattern.to_nfa_design

		start_state = Object.new
		accept_states = pattern_nfa_design.accept_states + [start_state]
		rules = pattern_nfa_design.rulebook.rules
		extra_rules = 
			pattern_nfa_design.accept_states.map { |accept_state| 
				FARule.new(accept_state, nil, pattern_nfa_design.start_state)
			} +
			[FARule.new(start_state, nil, pattern_nfa_design.start_state)]
		rulebook = NFARulebook.new(rules + extra_rules)

		NFADesign.new(start_state, accept_states, rulebook)
	end
end

#
# TEST7 正規表現の「*(閉包)」を非決定性有限オートマトンで表現
#

pattern = Repeat.new( Literal.new('a') )
# TEST7-1 # /a*/

pattern.matches?('')
# TEST7-2 # true

pattern.matches?('a')
# TEST7-3 # true

pattern.matches?('aaaa')
# TEST7-4 # true

pattern.matches?('b')
# TEST7-4 # false



#
# TEST8 複雑なパターンを作ってみよう！
#

pattern = 
	Repeat.new(
		Concatenate.new(
			Literal.new('a'),
			Choose.new( Empty.new, Literal.new('b') )
		)
	)
# TEST8-1 #　/(a(|b))*/

pattern.matches?('')
# TEST8-2 #　true

pattern.matches?('a')
# TEST8-3 #　true

pattern.matches?('aba')
# TEST8-4 #　true

pattern.matches?('abab')
# TEST8-5 #　true

pattern.matches?('abaab')
# TEST8-6 #　true

pattern.matches?('abba')
# TEST8-7 #　false



# 正規表現をつくるとき、いちいちRubyを書くのはめんどくさい
# →パーサに任せよう！→Treetopを使おう！

# 手順１　treetopを読み込む
require "treetop"

# 手順2　treetopのための文法PEGで書かれた、.treetopファイルをロードする
Treetop.load('pattern')

# 手順３　正規表現をパーサにかけよう
parse_tree = PatternParser.new.parse('(a(|b))*')


#
# TEST9 パーサによってRubyコードに書き換えた正規表現は、ちゃんと動くか？
#

pattern = parse_tree.to_ast
# TEST9-1 #　/(a(|b))*/

pattern.matches?('abaab')
# TEST9-2 #　true

pattern.matches?('abba')
# TEST9-3 # false