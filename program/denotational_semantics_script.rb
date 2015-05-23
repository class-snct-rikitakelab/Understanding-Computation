#
# 表示的意味論の説明用ソースコード
#

require "./big_step_script.rb"



#
# 表示的意味論とは？
# →　「与えられたコードを、他の誰かが理解できる数学的オブジェクト等に変換する学問(みたいなもの)」
#
# →→　他の誰か？
# →→→　ここでは、SIMPLEのコードをRubyで扱えるようにする。
#
# →→　数学的オブジェクト？
# →→→　ここでは式とか値とか
#

#
# 値や式をオブジェクトとして扱いたい（変数に保持したい）
# お、それっぽいことができる機能があるぞ？
# ラムダ式だ！
#

#
# 少しおさらい
# Proc(ラムダ式)
#

#
# function = -> arg1, arg2 {contents}
# function.call(arg1, arg2)
#

function = -> x, y {x + y}
function.call(3, 4)
# 7





#
#　まずは、数学的オブジェクトの最小単位である、数と真理値をRubyコードの「文字列」に変換
# eは、環境environmentのe
# ここではまだ変数と値を結びつける動作はしない（eをcontentsで使わない)が、
# 全ての数学的オブジェクトは、「環境を扱える」ということを表現している
#
class Number
	def to_ruby
		"-> e { #{value.inspect} }"
	end
end

class Boolean
	def to_ruby
		"-> e { #{value.inspect} }"
	end
end



#
# TEST1: SIMPLEで使っていた Number.new(5) を、　
#		 Ruby の 数学的オブジェクトの記号 に変換
#

Number.new(5).to_ruby
# "-> e { 5 }"

Boolean.new(false).to_ruby
# "-> e { false }"



#
# ソースコード「文字列」？
# 今出力できるのは、単なる文字列。
# Rubyがソースコードとして解釈するには、eval関数を使う。
# eval関数は、与えられた文字列を、実行可能なラムダ式に変換する
#

#
# TEST2: eval関数にソースコード「文字列」を与えて、
# 		 Rubyにソースコードとして解釈させる
#

eval( "-> e { 10 }" ).call({})
# 10

proc = eval( Number.new(5).to_ruby )
proc.call({})
# 5

proc = eval( Boolean.new(false).to_ruby )
proc.call({})
# false



#
# 今、数字や真理値を数学的オブジェクトとして扱える。
# 次は、変数(環境)をRubyの世界でも使えるようにしよう！
# 変数クラスVariableは、与えられた環境の中から、
# 自分の名前と一致する値を取り出し、表示する。
#

class Variable
	def to_ruby
		"-> e { e[ #{name.inspect} ] }"
	end
end



#
# TEST3: 変数と、その値を、環境によって結び付けられるようになった！
#

# 変数の名前
expression = Variable.new(:x)
# <<x>>

# Rubyにとっては、変数の名前についてる値を出力する命令
expression.to_ruby
# "-> e { e{:x} }"

# Rubyで実行する。
proc = eval(expression.to_ruby)
proc.call({ x: 7 })
# 7



# 環境が渡されていなければ、デフォルトはnil(全てのオブジェクトの初期値)
proc.call({})
# nil

# ちなみにRubyにnullはない模様。
# 代わりに、nilという「オブジェクト」が「存在する」。

nil.class
# NilClass

# 誰かいますか～？　誰もいませんよ～？
nil.nil?
# true



# 
# 表示的意味論で重要なのは、合成性！
# →　合成性？
# →→　いくつかの数学的オブジェクトを何らかの意味で組み合わせ、
# 	 新たな意味を導くこと。
#
# 合成の例として、足し算、掛け算、レス算。　Rubyコードで計算
# 左右に環境を渡して、callする。
#
class Add
	def to_ruby
		"-> e { ( #{left.to_ruby} ).call(e) + ( #{right.to_ruby} ).call(e) }"
	end
end

class Multiply
	def to_ruby
		"-> e { ( #{left.to_ruby} ).call(e) * ( #{right.to_ruby} ).call(e) }"
	end
end

class LessThan
	def to_ruby
		"-> e { ( #{left.to_ruby} ).call(e) < ( #{right.to_ruby} ).call(e) }"
	end
end



#
# TEST4: 合成性を持った数学的オブジェクトを宣言してみる
#

# x + 1 の数学的オブジェクト
Add.new(Variable.new(:x), Number.new(1)).to_ruby
# ごちゃごちゃ

# x + 1 < 3　の数学的オブジェクト
LessThan.new( Add.new( Variable.new(:x), Number.new(1) ), Number.new(3) ).to_ruby
# ぐちゃぐちゃ



#
# TEST5:　合成性を持った数学的オブジェクトをRubyで計算させる。
#

# 環境となるハッシュを作る
environment = { x: 3 }
# {:x=>3}

# x + 1, 環境により、x = 3
proc = eval( Add.new( Variable.new(:x), Number.new(1) ).to_ruby )
proc.call( environment )
# 4

# x + 1 < 3, 環境により、x = 3
proc = eval(
	LessThan.new( Add.new( Variable.new(:x), Number.new(1) ), Number.new(3) ).to_ruby
)
proc.call( environment )
# false



#
#　中間まとめ
# SIMPLEによるコードをRubyで数学的オブジェクトとして扱うことを考えるようになった
# Rubyで数学的オブジェクトと環境を対応させられるようになった
# 合成性を持った3つの式をRubyで数学的オブジェクトとして計算できるようになった。
#