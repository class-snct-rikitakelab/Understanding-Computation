#
# スモールステップ意味論における「式」の説明用ソースコード
#





#
# 全般
#

# irb　--simple-promptの後ろにファイルネームを置いて実行する。
# Rubyのモンキーパッチ機能のおかげで対話的にクラスを拡張できるため、
#　テキストに沿って、対話的に記述する。
#　このファイルを読み込めば、続きから始められる。
# Rubyでは、関数名(変数)の、関数名と(を離すことはできない。
# 物事を簡単にするため、共通コードを抽出したくなるのを我慢しよう。
# 実習の性質上、ペアプログラミングが有効かもしれない。くだらないミスを防げる。





#
# やりたいこと
#

# Rubyを使って、「SIMPLE」というおもちゃレベルのプログラミング言語を作る！
# スモールステップ意味論に基づいて作る！
# その第1歩として、「式」に関する部分を作る！(計算機のようなもの)





#
# まずは、式の要素のクラスを定義する。
# Struct.newの継承で、あらかじめ属性を決められる。
#

# 数クラス定義
class Number < Struct.new(:value)
end

# 足し算クラス定義
class Add < Struct.new(:left, :right)
end

# 掛け算クラス定義
class Multiply < Struct.new(:left, :right)
end





#
# これをインスタンス化し、抽象構文木(式を構造的に表現したもの）を構築
# これにより、1 * 2 + 3 * 4　という式ができる。（まだ計算はできない）
#
Add.new(
	Multiply.new(Number.new(1), Number.new(2)),
	Multiply.new(Number.new(3), Number.new(4))
)





#
# 式を表示するとき、<<struct hoge fuga>>だと見づらいので、#inspectをオーバーライド
#

# 数クラスにメソッド追加
class Number
	
	# selfにアクセスすると、to_sが自動的に呼び出される。
	# 値そのものを返す
	def to_s
		value.to_s
	end

	# オブジェクトそのものにアクセスすると、inspectが自動的に呼び出される。
	# Numberオブジェクトを参照したときの動作
	def inspect
		"<<#{self}>>"
	end

end



# 足し算クラスにメソッド追加
class Add

	# selfにアクセスすると、to_sが自動的に呼び出される。
	# 足し算の式を返す
	def to_s
		"#{left} + #{right}"
	end

	# オブジェクトそのものにアクセスすると、inspectが自動的に呼び出される。
	# Addオブジェクトを参照したときの動作
	def inspect
		"<<#{self}>>"
	end
end



# 掛け算クラスにメソッド追加
class Multiply

	# selfにアクセスすると、to_sが自動的に呼び出される。
	# 掛け算の式を返す
	def to_s
		"#{left} * #{right}"
	end

	# オブジェクトそのものにアクセスすると、inspectが自動的に呼び出される。
	# Multiplyオブジェクトを参照したときの動作
	def inspect
		"<<#{self}>>"
	end
end





#
# メソッドのオーバーライドで、式が見やすくなった
#

# さっきの式をもう一度
Add.new(
	Multiply.new(Number.new(1), Number.new(2)),
	Multiply.new(Number.new(3), Number.new(4))
)

# 最終的に出てくる式の全体に<<>>が付く
# irbによる表示⇒inspectメソッド
# オブジェクトの参照⇒to_sメソッド
#　irbで呼び出してるのは一番外側のオブジェクトだけ
Number.new(5)





#
# 今回の実装は、計算の優先順位を考慮しない。
# 意味論の説明にはあまり関係ないので、「3.3.1構文」でその問題を取り扱う。
#

# 1 * ( (2 + 3) * 4) (= 20)　という計算をしたいが、　
# 1 * 2 + 3 * 4　(= 14) と表示されてしまう。
# これに関しては話を簡単にするため一時的に無視する。
Multiply.new(
	Number.new(1),
	Multiply.new(
		Add.new(Number.new(2), Number.new(3)),
		Number.new(4)
	)
)





#
# 式を作ることができたので、簡約を行うメソッドを、各クラスに追加（モンキーパッチング）したい。
# 簡約とは、例えば　1 + 1 を　2　に変えること。　式が短くなる⇒簡約
# その準備として、各要素が簡約可能かどうかを返すメソッドを追加する。
#

# 数は、それ以上簡約できない。
class Number
	def reducible?
		false
	end
end

# 足し算は、足し算の結果に置き換えることで簡約できる。
class Add
	def reducible?
		true
	end
end

# 掛け算は、掛け算の結果に置き換えることで簡約できる。
class Multiply
	def reducible?
		true
	end
end





#
# 期待通り、簡約可能かを返すことが分かる。
#

# 1 簡約不可
Number.new(1).reducible?

# 1 + 2　簡約可能
Add.new(Number.new(1), Number.new(2)).reducible?





#
# 実際に簡約を行うメソッドを追加する。
# Numberには追加不要。
#

# 左優先で簡約していく。
#　左右とも簡約できなければ、数値が渡されているので、足し算して返す。
class Add
	def reduce
		if left.reducible?
			Add.new(left.reduce, right)
		elsif right.reducible?
			Add.new(left, right.reduce)
		else
			Number.new(left.value + right.value)
		end
	end
end



# 左優先で簡約していく。
#　左右とも簡約できなければ、数値が渡されているので、掛け算して返す。
class Multiply
	def reduce
		if left.reducible?
			Add.new(left.reduce, right)
		elsif right.reducible?
			Add.new(left, right.reduce)
		else
			Number.new(left.value * right.value)
		end
	end
end

# なぜnewなのかというと、reduceは式を変更しているのではなく、実際は新しい式を作っているから。
# !　オブジェクト指向的には、こういう長いif,elseをどうやって捌くのだろう？





#
# 簡約メソッドを実装したということは、計算ができるようになったということ。
# reduceを1回行うごとに、式が簡約されていき、すごくスモールステップらしい。
#

# 最初の式を作る。　1 * 2 + 3 * 4
expression = Add.new(
	Multiply.new(Number.new(1), Number.new(2)),
	Multiply.new(Number.new(3), Number.new(4))
)

# 簡約できなくなるまで手動で簡約を続ける。
expression.reducible?

expression = expression.reduce

expression.reducible?

expression = expression.reduce

expression.reducible?

expression = expression.reduce

expression.reducible?

# 式の簡約によって、答えを求められた。





#
# 今やった計算を自動でやってくれるVirtual Machine(仮想計算機)クラスを作る。
#

# 式オブジェクトを渡すと簡約し続ける
class Machine < Struct.new(:expression)
	
	# 簡約を1ステップ進める
	def step
		self.expression = expression.reduce
	end

	# 式の途中経過を表示しながら、簡約できなくなるまで簡約する。
	def run
		while expression.reducible?
			puts expression
			self.step
		end

		# 最終結果を表示
		puts expression
	end

end





#
# 仮想計算機に式を与えてインスタンス化し、走らせる。
#

Machine.new(
	Add.new(
	Multiply.new(Number.new(1), Number.new(2)),
	Multiply.new(Number.new(3), Number.new(4))
	)
).run





#
# 計算機の基礎部分ができた。
# 真理値と小なり演算子(<)の機能を追加する。
#

# 真理値クラス定義
class Boolean < Struct.new(:value)

	# 真理値を返す
	def to_s
		value.to_s
	end

	# 真理値オブジェクトを参照したときの動作
	def inspect
		"<<#{self}>>"
	end

	# 真理値は簡約不可
	def reducible?
		false
	end

end



# 小なり(<)クラス定義
class LessThan < Struct.new(:left, :right)

	# 不等式を返す
	def to_s
		"#{left} < #{right}"
	end

	# 小なりオブジェクトを参照したときの動作
	def inspect
		"<<#{self}>>"
	end

	#　小なりは、不等式が正しいかを判定し、真理値を返す。
	def reducible?
		true
	end

	# 左優先で簡約していく。
	# 左右とも簡約できなければ、数値が渡されているので、不等式の正誤を真理値で返す。
	def reduce
		if left.reducible?
			LessThan.new(left.reduce, right)
		elsif right.reducible?
			LessThan.new(left, right.reduce)
		else
			Boolean.new(left.value < right.value)
		end
	end

end





#
# 不等式が正しいかどうかが、簡約によってわかる！
#

Machine.new(
	LessThan.new(
		Number.new(5),
		Add.new(Number.new(2), Number.new(2))
		)
).run





#
# よりプログラミング言語っぽくするために、変数を扱えるようにする。
# 変数と、それに対応する値のメモ帳として、environment（環境）というハッシュ(連想配列）を導入する。
# この計算機の中では、xは5とか、yは3とか、そういうルールを決めるものだから、環境と呼ぶ。
# 全ての簡約メソッドに、Variableまでハッシュを届けるための引数を追加する必要がある。
#

# 変数を表現するクラスを定義する。
# 変数の名前を属性に持つ。
class Variable < Struct.new(:name)
	
	# 変数名を返す
	def to_s
		name.to_s
	end

	# 変数を参照したときの動作
	def inspect
		"<<#{self}>>"
	end

	# 変数における簡約とは、変数を、変数名に対応する値に置き換えること。
	# x = 5 となっていたら、　x + 3 を　5 + 3　に簡約する作業。
	def reducible?
		true
	end

	# 簡約メソッド
	# 上位の簡約メソッドに運んできてもらったenvironmentハッシュに、
	# 自身のキーを渡して、その返り値を得る。
	# 例えば、name が x なら 5 に置き換えられる。
	def reduce(environment)
		environment[name]
	end

end





#
# 変数を表現するために、各簡約メソッドを、変数に対応させる。
# Variableまでハッシュを届けるために、引数を追加する。
# 各reduceメソッドをオーバーライドする。
#

# 足し算クラスの簡約メソッドをオーバーライド
class Add
	def reduce(environment)
		if left.reducible?
			Add.new(left.reduce(environment), right)
		elsif right.reducible?
			Add.new(left, right.reduce(environment))
		else
			Number.new(left.value + right.value)
		end
	end
end



# 掛け算クラスの簡約メソッドをオーバーライド
class Multiply
	def reduce(environment)
		if left.reducible?
			Add.new(left.reduce(environment), right)
		elsif right.reducible?
			Add.new(left, right.reduce(environment))
		else
			Number.new(left.value * right.value)
		end
	end
end



# 小なり(<)クラスの簡約メソッドをオーバーライド
class LessThan
	def reduce(environment)
		if left.reducible?
			Add.new(left.reduce(environment), right)
		elsif right.reducible?
			Add.new(left, right.reduce(environment))
		else
			Boolean.new(left.value < right.value)
		end
	end
end




#
# Machineクラスのnewメソッドにenvironmentハッシュ引数を追加するため、作り直す。
#

# Machineクラス削除
Object.send(:remove_const, :Machine)



#　environment引数を追加し、作り直す
class Machine < Struct.new(:expression, :environment)
	
	#簡約を1ステップ進める。
	#
	def step
		self.expression = expression.reduce(environment)
	end

	#式の途中経過を表示しながら、簡約できなくなるまで簡約する。
	def run
		while expression.reducible?
			puts expression
			step
		end

		#最終結果を表示
		puts expression
	end

end



#
# environmentハッシュを導入し、変数を含む式を簡約できるようにした。
#

Machine.new(

	#　式、x + y　という変数を使えるようになった。　Machineの第1引数
	Add.new(Variable.new(:x), Variable.new(:y)),

	#　これがハッシュ。Machineの第2引数
	{x: Number.new(3), y: Number.new(4)}
).run

# 全ての変数には、対応する値がなければ、計算は終了しない。
# 例えば、yが定義されていないとき、3 + y　で終わったりしない。
# 対応する値のない変数がある式が正常に終了する方が危険。





#
# 式の操作的意味論を表す、仮想的な計算機が完成した。
# 次は、もう一つのスモールステップ操作的意味論の構成要素である、文法について見ていく。
#