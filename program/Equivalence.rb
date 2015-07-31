

# NFAからDFAへの変換をRubyで実装する。

# NFAのシミュレーションの情報をまとめ、その情報をDFAに変換するための、NFASimurationというクラスを作る。
# NFASimurationのインスタンスは、特定のNFADesignクラスのために作られ、
# 最終的にNFASimuration#to_dfa_designメソッドで等価なDFADesignに変換する。


require "./regular_expression.rb"


# NFAをシミュレートできるNFAクラスはすでにあるので、
# NFASimurationはNFAのインスタンスを生成し、
# それがどのようにして可能な入力すべてに応答するかを調べる事ができる。

# NFASimurationにとりかかる前に、新しくNFADesign#to_nfa に"current states"を加える。
# これによりNFAインスタンスをNFADesignの開始状態ではなく、現在の状態を決めてNFAインスタンスを生成することができる。


class NFADesign
	# Set[X] という引数が来たら、Xを現在の状態にするのを追加
	def to_nfa(current_states = Set[start_state])
		NFA.new(current_states, accept_states, rulebook)
	end
end

# NFAのシミュレーションは開始状態からしか始められなかった。
# 今追加した新しいパラメータにより、別の点にジャンプしてそこから始めることができるようになった。


# rulebook = NFARulebook.new([
# 	FARule.new(1, 'a', 1), FARule.new(1, 'a', 2), FARule.new(1, nil, 2),
# 	FARule.new(2, 'b', 3),
# 	FARule.new(3, 'b', 1), FARule.new(3, nil, 2)
# ])


# >> nfa_design = NFADesign.new(1, [3], rulebook)
# => #<struct NFADesign start_state=1, accept_states=[3], rulebook=#<struct NFARulebook rules=[#<FARule 1 --a--> 1>, #<FARule 1 --a--> 2>, #<FARule 1 ----> 2>, #<FARule 2 --b--> 3>, #<FARule 3 --b--> 1>, #<FARule 3 ----> 2>]>>
# >> nfa_design.to_nfa.current_states
# => #<Set: {1, 2}>
# >> nfa_design.to_nfa(Set[2]).current_states
# => #<Set: {2}>
# >> nfa_design.to_nfa(Set[3]).current_states
# => #<Set: {3, 2}>


	# NFAクラスは自動的に自由移動を評価する。
	# よってNFASimurationでそれに関して特別な処理をする必要はない。


# これで取りえる状態を決めてNFAを作り、文字を入力し、最後にはどの状態になる可能性があるかを見ることができる。
# これはNFAをDFAに変換する上で重要なステップです。
# さっきのNFAで状態2か3でbを読み込む時、その後どうなるか?


# >> nfa = nfa_design.to_nfa(Set[2, 3])
# => #<struct NFA current_states=#<Set: {2, 3}>, accept_states=[3], rulebook=#<struct NFARulebook rules=[#<FARule 1 --a--> 1>, #<FARule 1 --a--> 2>, #<FARule 1 ----> 2>, #<FARule 2 --b--> 3>, #<FARule 3 --b--> 1>, #<FARule 3 ----> 2>]>>
# >> nfa.read_character('b'); nfa.current_states
# => #<Set: {3, 1, 2}>


# この答えは、手動で変換した時と同じで状態1,2,3となる。 (Setは要素の順番を考慮しない)


# これを利用して、NFASimurationクラスを作り、
# それぞれの入力でどのようにシミュレーションの状態が変わるのかを計算するメソッドを追加する。
# シミュレーションの状態をNFAがとり得る状態(1,2 や 3)だと考え、
# これを、#next_stateメソッドをシミュレーションの状態と入力文字、文字に対応するNFAの状態から、
# 新しいNFAの状態を返すものとして作る事ができる。


class NFASimulation < Struct.new(:nfa_design)
	# 状態と入力文字から新しい状態を返す (文字とNFAの対応はNFASimurationが持っている)
	def next_state(state, character)
		nfa_design.to_nfa(state).tap { |nfa|
			nfa.read_character(character)
		}.current_states
	end
end


	# シミュレーションの状態(NFASimuretion#naxt_stateのstate引数)は、複数のNFAの集合で出来ているため、
	# NFASimuration#next_stateのcurrent_states引数に与えることが出来る。


# >> simulation = NFASimulation.new(nfa_design)
# => #<struct NFASimulation nfa_design=#<struct NFADesign start_state=1, accept_states=[3], rulebook=#<struct NFARulebook rules=[#<FARule 1 --a--> 1>, #<FARule 1 --a--> 2>, #<FARule 1 ----> 2>, #<FARule 2 --b--> 3>, #<FARule 3 --b--> 1>, #<FARule 3 ----> 2>]>>>
# >> simulation.next_state(Set[1, 2], 'a')
# => #<Set: {1, 2}>
# >> simulation.next_state(Set[1, 2], 'b')
# => #<Set: {3, 2}>
# >> simulation.next_state(Set[3, 2], 'b')
# => #<Set: {1, 3, 2}>
# >> simulation.next_state(Set[1, 3, 2], 'b')
# => #<Set: {1, 3, 2}>
# >> simulation.next_state(Set[1, 3, 2], 'a')
# => #<Set: {1, 2}>


# これで、シュミレーションの状態を調べやすくなった。


# シミュレーション状態をDFA状態として直接利用することにする。
# そのために、シミュレーション状態を体系的に調べて、DFAの状態や規則として記録する方法が必要になる。

# まず、NFASimuration#rules_forを実装する。
# このメソッドは、#next_stateを使ってそれぞれの規則による移動先を見つけ、特定のシミュレーション状態におけるすべての規則を展開する。
# ここで、すべての規則とは、取りえる入力に対する規則のことを表す。
# なので、もとのNFAがどんな文字を読めるのかを教える、NFARulebook#alphabetも定義する。


class NFARulebook
	# 読むことができる文字を返す
	def alphabet
		rules.map(&:character).compact.uniq
	end
end

class NFASimulation
	# 現在の状態のそれぞれの入力に対する新しい状態を返す
	def rules_for(state)
		nfa_design.rulebook.alphabet.map { |character|
			FARule.new(state, character, next_state(state, character))
		}
	end
end


# >> rulebook.alphabet
# => ["a", "b"]
# >> simulation.rules_for(Set[1, 2])
# => [#<FARule #<Set: {1, 2}> --a--> #<Set: {1, 2}>>,
#     #<FARule #<Set: {1, 2}> --b--> #<Set: {3, 2}>>]
# >> simulation.rules_for(Set[3, 2])
# => [#<FARule #<Set: {3, 2}> --a--> #<Set: {}>>,
#     #<FARule #<Set: {3, 2}> --b--> #<Set: {1, 3, 2}>>]


# 意図した通り、異なる入力は、異なる状態間をシミュレーションするのがわかる。


# #rules_forメソッドにより、シミュレーション状態から新しいシミュレーション状態が見つかる。
# これを繰り返せば、取りえるすべてのシミュレーション状態がわかる。
# そのために、NFASimuration#discover_states_and_rulesを定義する。
# これは、NFARulebook#follow_free_movesと同じように、状態を再帰的に見つける。


class NFASimulation
	def discover_states_and_rules(states)
		rules = states.flat_map { |state| rules_for(state) }
		more_states = rules.map(&:follow).to_set

		if more_states.subset?(states)
			[states, rules]
		else
			discover_states_and_rules(states + more_states)
		end
	end
end


	# statesとmore_statesの二つの変数はどちらもシミュレーション状態の集合だが、
	# シミュレーション状態はNFA状態の集合なので、この二つの変数は実際にはNFA状態の集合の集合になる。


# 最初にわかっているシミュレーション状態はNFAを開始状態にしたときにNFAがとる集合で、
# #discover_states_and_rulesは、ここから調べていき、最終的に4つのシミュレーション状態と8つの規則をすべて見つける。


# >> start_state = nfa_design.to_nfa.current_states
# => #<Set: {1, 2}>
# >> simulation.discover_states_and_rules(Set[start_state])
# => [#<Set: {#<Set: {1, 2}>, #<Set: {3, 2}>, #<Set: {}>, #<Set: {1, 3, 2}>}>,
#    [#<FARule #<Set: {1, 2}> --a--> #<Set: {1, 2}>>,
#     #<FARule #<Set: {1, 2}> --b--> #<Set: {3, 2}>>,
#     #<FARule #<Set: {3, 2}> --a--> #<Set: {}>>,
#     #<FARule #<Set: {3, 2}> --b--> #<Set: {1, 3, 2}>>,
#     #<FARule #<Set: {}> --a--> #<Set: {}>>,
#     #<FARule #<Set: {}> --b--> #<Set: {}>>,
#     #<FARule #<Set: {1, 3, 2}> --a--> #<Set: {1, 2}>>,
#     #<FARule #<Set: {1, 3, 2}> --b--> #<Set: {1, 3, 2}>>]]


# 最後に、シミュレーション状態を受理状態として扱うべきかを調べる。
# これはNFAに問い合わせれば簡単にチェックできる。


# >> nfa_design.to_nfa(Set[1, 2]).accepting?
# => false
# >> nfa_design.to_nfa(Set[2, 3]).accepting?
# => true


# これで必要なものはすべてそろったので、これをDFADesignのインスタンスとしてまとめられるように、
# NFASumilation#to_dfa_designを用意する。


class NFASimulation
	def to_dfa_design
		start_state = nfa_design.to_nfa.current_states
		states, rules = discover_states_and_rules(Set[start_state])
		accept_states = states.select { |state| nfa_design.to_nfa(state).accepting? }

		DFADesign.new(start_state, accept_states, DFARulebook.new(rules))
	end
end


# これで、任意のNFAからNFASimulationインスタンスを生成し、
# それを同じ文字列を受理するDFAに変換することができる。


# >> dfa_design = simulation.to_dfa_design
# => #<struct DFADesign start_state=#<Set: {1, 2}>,
#      accept_states=[#<Set: {3, 2}>, #<Set: {1, 3, 2}>],
#      rulebook=#<struct DFARulebook rules=[#<FARule #<Set: {1, 2}> --a--> #<Set: {1, 2}>>,
                #<FARule #<Set: {1, 2}> --b--> #<Set: {3, 2}>>,
                #<FARule #<Set: {3, 2}> --a--> #<Set: {}>>,
                #<FARule #<Set: {3, 2}> --b--> #<Set: {1, 3, 2}>>,
                #<FARule #<Set: {}> --a--> #<Set: {}>>,
                #<FARule #<Set: {}> --b--> #<Set: {}>>,
                #<FARule #<Set: {1, 3, 2}> --a--> #<Set: {1, 2}>>,
                #<FARule #<Set: {1, 3, 2}> --b--> #<Set: {1, 3, 2}>>]>>
# >> dfa_design.accepts?('aaa')
# => false
# >> dfa_design.accepts?('aab')
# => true
# >> dfa_design.accepts?('bbbabb')


# 素晴らしい！

# NFAで追加された機能はDFAではできないことなのか、その答えは明らかにノー。
# NFAがDFAに同じ機能を持ったまま変換できるということは、NFAで何らかの能力が追加されたわけではないということです。
# 非決定性と自由移動はDFAで出来たことを便利になるようにパッケージングしなおしただけで、決定性の制約を超えて、新しいことができるようになるわけではない。

# 単純な機械に機能を追加しても、基本的にもともと出来ないものが出来るようになるわけではない、ということは理論的にも興味深いことである。
# だが、これは実践的にも役に立つ。なぜなら、DFAは、NFAよりシミュレートするのが簡単だからである。
# DFAは、記録する必要のある状態は現在の状態1つだけであり、
# ハードウェアや、マシンコードに直接実装することも簡単で、プログラムの場所を状態として、条件分岐命令を規則として使うことが出来る。
# これにより、正規表現を実装するときに、まずパターンをNFAに変換して、そこからDFAに変換することで、シミュレートが高速で効率よく行えるとても単純な機械が得られる。




# これ以上少ない状態数で設計できないDFAは、最小であるという。
# NFAからDFAに変換するとき、最小でないDFAができる時がある。
# これを最小にするBrzozowskiのアルゴリズムというものがあるが、省略する。