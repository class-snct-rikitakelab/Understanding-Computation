
#正規表現

#	正規表現：文字列に対して条件がマッチしているかどうか判定するための記法

#	例）
#	・hello → "hello"のときのみ真を返す。
#	・hello|goodbye → "hello"もしくは"goodbye"が記述されているときのみ真を返す。
#	・(hello)* → "hello","hellohello"など"hello"の文字列が繰り返すときのみ真を返す。　""の時でも真。

#	NFAを用いて実現する

#今回実装するもの

#	2つの要素
#		・Empty regular expression ：　空の正規表現，何もないこと 
#			例) (|a) だったなら ""もしくは"a"で真を返す。

#		・Literal character：単一の文字
#			例）"a"とか"b"など"ab"は文字列なので該当しない。


# NFAのソースコードを取り込む
require "./The_Simplest_Computer.rb" 


module Pattern						#patternをカッコで囲むかどうかを判断するモジュール

	def bracket(outer_precedence)			#自身の優先度が高いと，カッコで括られて出力される
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

class Empty						#空の正規表現を実装
	include Pattern					#Patternモジュールを組み込む

	def to_s
		''
	end

	def precedence					#空の正規表現の優先度は3
		3
	end
end

class Literal < Struct.new(:character)			#単独の文字を実装
	include Pattern

	def to_s
		character
	end

	def precedence					#単独の文字の優先度は3
		3
	end
end

#	2つのpattern
#		・Concatenate：　文字を連結する。
#			例) "a"と"b"を連結して"ab"
#		・Choose：　二つのpatternのどちらかを選択する。
#			例）hello|goodbye → "hello"もしくは"goodbye"が記述されているときのみ真を返す。
#		・Repeat：　0回以上の繰り返し
#			例）a* なら，""，"a"，"aa"，…の時に真を返す。

class Concatenate < Struct.new(:first, :second)						#文字の連接の表現を実装
	include Pattern

	def to_s
		[first, second].map { |pattern| pattern.bracket(precedence) }.join	#各要素がカッコで囲まれるべきかどうかを判定
	end										#その後，joinメソッドで連結する．

	def precedence									#連接の優先度は1
		1
	end
end

class Choose < Struct.new(:first, :second)						#選択の表現を実装
	include Pattern

	def to_s
		[first, second].map { |pattern| pattern.bracket(precedence) }.join('|')	#各要素がカッコで囲まれるべきかどうかを判定
	end										#その後，joinメソッドで連結する

	def precedence									#選択の優先度は0
		0
	end	
end

class Repeat < Struct.new(:pattern)							#繰り返しの表現を実装
	include Pattern

	def to_s			
		pattern.bracket(precedence) + '*'					#各要素がカッコで囲まれるべきかどうかを判定
	end										#その後，末尾に演算子を付加 (Literalの時のみカッコなしで演算子をつける)

	def precedence									#繰り返しの優先度は2
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

#意味論
#	これまでは表現に方法を定義した．
#	だが書き方を定義しただけで，意味は定義できていない。
#	ここからは表現に意味を付け加えていく

class Empty									#空の正規表現にNFAの規則を付加
	def to_nfa_design
		start_state = Object.new					#開始ステート，受理ステート，NFAの規則を定義していくことで意味づけをしていく
		accept_states = [start_state]
		rulebook = NFARulebook.new([])

		NFADesign.new(start_state, accept_states, rulebook)		#ルールもなく無条件に真を返す．
	end
end

class Literal
	def to_nfa_design
		start_state = Object.new					#開始ステートと
		accept_state = Object.new					#受理ステートをそれぞれ定義する．
		rule = FARule.new(start_state, character, accept_state)		#character の文字が入力されたら開始ステートから受理ステートに遷移．
		rulebook = NFARulebook.new([rule])

		NFADesign.new(start_state, [accept_state], rulebook)		#指定した文字が入力されたなら真を返す．
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

#patternモジュールにmathces?メソッドを追加
#NFAをあまり意識しなくなり，より使いやすくなる


module Pattern
	def matches?(string)
		to_nfa_design.accepts?(string)		#自動的にNFAを生成，文字列は受理されているか判定する
	end
end

#
# TEST3　直接受理状態か確認できるようにする
#

Empty.new.matches?('a')
# TEST3-1 # false

Literal.new('a').matches?('a')
# TEST3-2 # true

#続いて，正規表現の連結を実装する．


class Concatenate
	def to_nfa_design
		first_nfa_design = first.to_nfa_design						#firstとsecondのNFAをそれぞれ作成
		second_nfa_design = second.to_nfa_design

		start_state = first_nfa_design.start_state					#全体の開始ステートをfirstの開始ステートにする
		accept_states = second_nfa_design.accept_states					#全体の受理ステートをsecondの受理ステートにする

		rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules	#firstとsecondの規則をまとめる
		extra_rules = first_nfa_design.accept_states.map { |state| 			#firstの受理ステートからsecondの開始ステートへの自由移動を付加
			FARule.new(state, nil, second_nfa_design.start_state) 
		}
		rulebook = NFARulebook.new(rules + extra_rules)					#NFAを作成

		NFADesign.new(start_state, accept_states, rulebook)
	end
end

#
# TEST4 正規表現の「連結」を、非決定性有限オートマトンで表現
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
		first_nfa_design = first.to_nfa_design							#連接と同様
		second_nfa_design = second.to_nfa_design

		start_state = Object.new								#オブジェクトを開始ステートにする
		accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states	#firstとsecondの受理ステートを全体の受理ステートにする

		rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules		#firstとsecondのルールを合わせる
		extra_rules = [first_nfa_design, second_nfa_design].map { |nfa_design| 			#全体の開始ステートからfirstとseocondの開始ステートまでの自由移動を追加
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
		pattern_nfa_design = pattern.to_nfa_design					#連接と同様

		start_state = Object.new							#開始ステートをオブジェクトとして定義
		accept_states = pattern_nfa_design.accept_states + [start_state]		#受理ステートを内部の受理ステートと開始ステートにする

		rules = pattern_nfa_design.rulebook.rules					#内部の規則を全体の規則として追加

		extra_rules = 									#patternの受理ステートからpatternの開始ステートへの自由移動を追加
			pattern_nfa_design.accept_states.map { |accept_state| 			#全体の開始ステートからpatternの開始ステートへの自由移動を追加
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
>>>>>>> 7cca11989ad2776c5842c62f131f0e4dfaf8dfe3
