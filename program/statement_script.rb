#
# 前回の続き
#

require "./expression_script.rb"

#
# 文(statement)という違う種類のプログラムの構成を作る。
#
# 式は、ある式から新しい式を生成する。
# 一方、文は仮想計算機の状態を変える。
# この仮想計算機の持つ状態は環境だけだから、式で新しい環境を作って置き換える事ができるようにする。
#
# もっとも簡単な文は、なにもしないもので、簡約不能、そして環境にあらゆる影響を与えられないものである。
# これは簡単に作れる。
#


# 他のすべての構文クラスはstructクラスを継承しているが、DoNothingクラスは何も継承していない。
# これは、DoNothingは属性を持たず、struct.newには空の属性名のリストを渡すことができないためである。
class DoNothing
	def to_s
		'do-nothing'
	end

	def inspect
		"<<#{self}>>"
	end

# 他の構文クラスはStructクラスから同じか比較する演算を継承しているが、DoNothingクラスは何も継承していないため、これを自身で定義する。
	def ==(other_statement)
		other_statement.instance_of?(DoNothing)
	end

	def reducible?
		false
	end
end

#
# 何もしない文は、無意味に思えるかもしれないが、プログラムの実行が正常に完了していることを表す特別な文として使うことができる。
# DoNothingクラスをそういった使い方をするには、作業を終えたあと最終的に<<do-nothing>>に簡約される文を生成すればよい。
#


#
# 代入( x = x + 1 みたいなもの)を行える文を作る。
# これは次のような簡約ルールにしたがって実現する。
# 代入文は、変数名(x)と、変数に代入する式(x+1)からなる。
# 式が簡約可能ならば、式の簡約ルールによって簡約する。
# (例えば、 変数x=2のとき、 x = x + 1  →  x = 2 + 1  →  x = 3 )
# 式の簡約ができなくなったならば、実際に代入を行う。
# つまり導出した値を変数名に関連付けて環境を更新する。
#



# 代入クラス定義
class Assign < Struct.new(:name, :expression)
	def to_s
		"#{name} = #{expression}"
	end

	def inspect
		"«#{self}»"
	end

	def reducible?
		true
	end

# 式が簡約可能なら簡約する。
# 簡約できないなら、式と代入した変数を関係付けて環境を更新し、do-nothing文と新しい環境を返す。
# 代入クラスのreduceメソッドは文と環境の両方を返す必要があるが、Rubyのメソッドは1つのオブジェクトしか返すことができないため、文と環境を2要素配列に入れて返すことで２つのオブジェクトを返すように見せかける。
	def reduce(environment)
		if expression.reducible?
			[Assign.new(name, expression.reduce(environment)), environment]
		else
			[DoNothing.new, environment.merge({ name => expression })]
		end
	end
end

#
# 式と同じように、代入文を手動で簡約することにより評価できる。
#

#>> statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
#=> «x = x + 1»
#>> environment = { x: Number.new(2) }
#=> {:x=>«2»}
#>> statement.reducible?
#=> true
#>> statement, environment = statement.reduce(environment)
#=> [«x = 2 + 1», {:x=>«2»}]
#>> statement, environment = statement.reduce(environment)
#=> [«x = 3», {:x=>«2»}]
#>> statement, environment = statement.reduce(environment)
#=> [«do-nothing», {:x=>«3»}]
#>> statement.reducible?
#=> false

#
# 仮想計算機が文も扱えるようにする。
#

Object.send(:remove_const, :Machine)
class Machine < Struct.new(:statement, :environment)
	def step
		self.statement, self.environment = statement.reduce(environment)
	end

# 文と環境の途中経過を表示しながら、簡約できなくなるまで簡約する。
	def run
		while statement.reducible?
			puts "#{statement}, #{environment}"
			step
		end

		puts "#{statement}, #{environment}"
	end
end

# これで文にも対応した。

#>> Machine.new(
#Assign.new(:x, Add.new(Variable.new(:x), Number.new(1))),
#{ x: Number.new(2) }
#).run
#x = x + 1, {:x=>«2»}
#x = 2 + 1, {:x=>«2»}
#x = 3, {:x=>«2»}
#do-nothing, {:x=>«3»}
#=> nil

#
# 仮想計算機の簡約は、構文木のトップレベルではなく文の内部で行われる。
#

#Ifクラス
class If < Struct.new(:condition, :consequence, :alternative)
	def to_s
		"if (#{condition}) { #{consequence} } else { #{alternative} }"
	end

	def inspect
		"«#{self}»"
	end

	def reducible?
		true
	end

	def reduce(environment)
		if condition.reducible?
			[If.new(condition.reduce(environment), consequence, alternative), environment]
		else
			case condition
			when Boolean.new(true)
				[consequence, environment]
			when Boolean.new(false)
				[alternative, environment]
				end
				end
				end
			end


#Ifクラスを使った文
#>> Machine.new(
#	If.new(
#		Variable.new(:x),
#		Assign.new(:y, Number.new(1)),
#		Assign.new(:y, Number.new(2))
#		),
#	{ x: Boolean.new(true) }
#	).run
#if (x) { y = 1 } else { y = 2 }, {:x=>«true»}
#if (true) { y = 1 } else { y = 2 }, {:x=>«true»}
#y = 1, {:x=>«true»}
#do-nothing, {:x=>«true», :y=>«1»}
#=> nil

#>> Machine.new(
#	If.new(Variable.new(:x), Assign.new(:y, Number.new(1)), DoNothing.new),
#	{ x: Boolean.new(false) }
#	).run
#if (x) { y = 1 } else { do-nothing }, {:x=>«false»}
#if (false) { y = 1 } else { do-nothing }, {:x=>«false»}
#do-nothing, {:x=>«false»}
#=> nil

#Sequenceクラス
class Sequence < Struct.new(:first, :second)
	def to_s
		"#{first}; #{second}"
	end

	def inspect
		"«#{self}»"
	end

	def reducible?
		true
	end

	def reduce(environment)
		case first
		when DoNothing.new
			[second, environment]
		else
			reduced_first, reduced_environment = first.reduce(environment)
			[Sequence.new(reduced_first, second), reduced_environment]
		end
	end
end

#Sequenceクラスを利用した文？
#>> Machine.new(
#	Sequence.new(
#		Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
#		Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
#		),
#	{}
#	).run
#x = 1 + 1; y = x + 3, {}
#x = 2; y = x + 3, {}
#do-nothing; y = x + 3, {:x=>«2»}
#y = x + 3, {:x=>«2»}
#y = 2 + 3, {:x=>«2»}
#y = 5, {:x=>«2»}
#do-nothing, {:x=>«2», :y=>«5»}
#=> nil

#whileクラス
class While < Struct.new(:condition, :body)
	def to_s
		"while (#{condition}) { #{body} }"
	end

	def inspect
		"«#{self}»"
	end

	def reducible?
		true
	end

	def reduce(environment)
		[If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
	end
end

#whileクラスを利用した文
#>> Machine.new(
#	While.new(
#		LessThan.new(Variable.new(:x), Number.new(5)),
#		Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
#		),
#	{ x: Number.new(1) }
#	).run
#while (x < 5) { x = x * 3 }, {:x=>«1»}
#if (x < 5) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«1»}
#if (1 < 5) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«1»}
#if (true) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«1»}
#x = x * 3; while (x < 5) { x = x * 3 }, {:x=>«1»}
#x = 1 * 3; while (x < 5) { x = x * 3 }, {:x=>«1»}
#x = 3; while (x < 5) { x = x * 3 }, {:x=>«1»}
#do-nothing; while (x < 5) { x = x * 3 }, {:x=>«3»}
#while (x < 5) { x = x * 3 }, {:x=>«3»}
#if (x < 5) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«3»}
#if (3 < 5) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«3»}
#if (true) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«3»}
#x = x * 3; while (x < 5) { x = x * 3 }, {:x=>«3»}
#x = 3 * 3; while (x < 5) { x = x * 3 }, {:x=>«3»}
#x = 9; while (x < 5) { x = x * 3 }, {:x=>«3»}
#do-nothing; while (x < 5) { x = x * 3 }, {:x=>«9»}
#while (x < 5) { x = x * 3 }, {:x=>«9»}
#if (x < 5) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«9»}
#	if (9 < 5) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«9»}
#if (false) { x = x * 3; while (x < 5) { x = x * 3 } } else { do-nothing }, {:x=>«9»}
#do-nothing, {:x=>«9»}
#=> nil


#>> Machine.new(
#	Sequence.new(
#		Assign.new(:x, Boolean.new(true)),
#		Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
#		),
#	{}
#	).run
#x = true; x = x + 1, {}
#do-nothing; x = x + 1, {:x=>«true»}
#x = x + 1, {:x=>«true»}
#x = true + 1, {:x=>«true»}
#NoMethodError: undefined method `+' for true:TrueClass