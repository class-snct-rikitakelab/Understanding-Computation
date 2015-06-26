##CHAPTER 3
##The Simplest Computers

##Deterministic Finite Automata

##決定性有限オートマトン##

#典型的な現実のコンピュータは揮発性のメモリ(RAM)と不揮発性のメモリ(HDD or SSD)、入出力装置、CPUより構成されている
#有限オートマトンの様な有限性マシンはシンプルなコンピュータのモデルであるためにコンピュータのハードウェア、ソフトウェア両方を学ぶことが簡単に行える


##Simulation##
#決定性有限オートマトンは抽象的な計算機を表しているつもりである
#スライドで例題より振る舞いを示した(スライド参照)がそれらは物理的に存在ていない
#よってそれらは理論的にしか振舞うことが出来ない
#しかし、決定性有限オートマトンはシンプルなため、シミュレーションが楽である
#そのため実際にプログラムを作成する

#rulebook#

#FARuleオブジェクトは1つのルールの情報を保持している
class FARule < Struct.new(:state, :character, :next_state)

	#各ルールには'true' か 'false'で返すことのできる'#applies_to?'メソッドがある
	#このメソッドはルールがこのシチュエーション内に当てはまるかを知らせる役割を持つ
	def applies_to?(state, character)
		self.state == state && self.character == character
	end
	
	# '#follow'メソッドはマシンがどのように変わるべきかの情報を返す
	def follow
		next_state
	end
	
	def inspect
		"#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}>"
	end
end

#DFARulebookはFARulebookを複数保持している
class DFARulebook < Struct.new(:rules)

	# '#next_state'はFARulebookの'#follow'を
	#正しい経路を探索するために用いている
	def next_state(state, character)
 		rule_for(state, character).follow
	end

	# '#rule_for'メソッドは'#next_state'メソッドより引数を受け取り、その状態が存在するか確認する
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

#DFAクラスは現在の状態を保持するオブジェクトである
#構成には上記で作成したrulebookを利用している
class DFA < Struct.new(:current_state, :accept_states, :rulebook)
	
	# '#accepting'メソッドは現在の状態が認められたリストの中に入っているか確認する
	def accepting?
		accept_states.include?(current_state)
	end

	# このメソッドでは入力に文字を利用することができ、rulebookを調べ、
	#それに応じて状態を変えることができる
	def read_character(character)
		self.current_state = rulebook.next_state(current_state, character)
	end

	# 文字の変わりに文章を打ち、状態を変えることができる
	def read_string(string)
		string.chars.each do |character|
			read_character(character)
		end
	end
end

#今までの状態だと入力を与えるとどうであれ状態が始やり直すときに始まってしまった。
#そのため次の入力も完璧に行わなければいけなく、一回限りで終了する
#これが意味するものは、もし同じ状態でリスタートするときにはまた条件を再入力しなくてはならないということである

#よってDFADesignでは一回条件を作成すると状態判断を複数回実行できるようになっている

class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
	
	#新しいDFAを作成する
	def to_dfa
		DFA.new(start_state, accept_states, rulebook)
	end
	
	# '#to_dfa'を利用して、dfaの'#read_string'を呼び出す
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