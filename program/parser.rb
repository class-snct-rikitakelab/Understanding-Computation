require "./denotational_semantics_script.rb"

# これまでは、 Assign.new(:x, Add.new(Variable.new(:x), Number.new(1))) のように手書きでRubyの式を記述してSIMPLEの抽象構文木を構築してきた。
# この章では、パーサを使い 'x = x + 1' のようなSIMPLEのソースコードを自動的に抽象構文木に変える。

# はじめからパーサを実装しようとすると、意味論の話からそれすぎてしまう。
# パーサのツールとライブラリがすでにあるので、使わせてもらうことにする。
# ここではその方法の概略を説明する。

# Rubyで使えるパーサのツールの一つが Treetop というドメイン固有言語で、
# パーサが自動的に生じるのを許可するような構文を記述するものです。
# sudo gem install treetop で入手可能
# Treetopの構文の記述は、 Parsing Expression Grammar として書かれる。
# (PEG: 正規表現のような規則で、書いたり理解したりするのが簡単な、単純な集まり)
# 何よりも、これらの規則は、メソッドの定義にアノテーション(注釈)をつけることができる。
# つまり、構文解析のプロセスによって生成されたRubyのオブジェクトは、それ自身の振る舞いを与えられることができる。
# 文法の構造と、文法どおりに動作するRubyのコードの集まり のどちらとも定義することができるので、
# Treetopは構文の言語を書き出して、実行可能な意味論を与えるのに理想的である。

# これがどのように動くのかを見るため、SIMPLE用のTreetopの文法の削減版がsimple.treetopにある。
# これは文字列 'while (x < 5) { x =x * 3 }' を構文解析するために必要な規則だけが含まれる。






# simple.treetopというファイルに保存されているSIMPLE用の文法を、Treetopでファイルを読みこむことにより、SimpleParserクラスを生成することができる。
# このパーサはSIMPLEのソースコードをTreetopのSyntaxNodeのためにビルドして表現する

require 'treetop'
# => true
Treetop.load('simple')
# => SimpleParser
# >> parse_tree = SimpleParser.new.parse('while (x < 5) { x = x * 3 }')
# => SyntaxNode+While1+While0 offset=0, "...x < 5) { x = x * 3 }" (to_ast,condition,body):
#   SyntaxNode offset=0, "while ("
#   SyntaxNode+LessThan1+LessThan0 offset=7, "x < 5" (to_ast,left,right):
#     SyntaxNode+Variable0 offset=7, "x" (to_ast):
#       SyntaxNode offset=7, "x"
#     SyntaxNode offset=8, " < "
#     SyntaxNode+Number0 offset=11, "5" (to_ast):
#       SyntaxNode offset=11, "5"
#   SyntaxNode offset=12, ") { "
#   SyntaxNode+Assign1+Assign0 offset=16, "x = x * 3" (to_ast,name,expression):
#     SyntaxNode offset=16, "x":
#       SyntaxNode offset=16, "x"
#     SyntaxNode offset=17, " = "
#     SyntaxNode+Multiply1+Multiply0 offset=20, "x * 3" (to_ast,left,right):
#       SyntaxNode+Variable0 offset=20, "x" (to_ast):
#         SyntaxNode offset=20, "x"
#       SyntaxNode offset=21, " * "
#       SyntaxNode+Number0 offset=24, "3" (to_ast):
#         SyntaxNode offset=24, "3"
#   SyntaxNode offset=25, " }"


# このSyntaxNodeの構造は、具象構文木です。
# これは特にTreetopパーサによる走査のために設計されているため、
# ノードがもとのソースコードとどのように関連するか、についてのたくさんの関係ない情報を含む。
# Treetopのドキュメントには、構文木を自分で走査しないように、
# その代わりに自分に必要なものを適切な形で返すようなメソッドをルート規則に追加するように書いてある。

# #to_asmメソッドがそのために追加したメソッドです。
# 構文木を直接操作せずに、アノテーションを加える機能を使って、#to_astメソッドを各ノードに定義した。
# to_astメソッドをルートノードで呼び出すと、SIMPLEの構文オブジェクトから抽象構文木を作ります。
# >> statement = parse_tree.to_ast
# => «while (x < 5) { x = x * 3 }»


# これで、ソースコードを自動的に抽象構文木に変換することができるようになった。
# そして、これまで通りにプログラムを調べることができる。
# >> statement.evaluate({ x: Number.new(1) })
# => {:x=><<9>>}
# >> statement.to_ruby
# => "-> e { while (-> e { ( -> e { e[ :x ] } ).call(e) < ( -> e { 5 } ).call(e) }).call(e); e = (-> e { e.merge({ :x => (-> e { ( -> e { e[ :x ] } ).call(e) * ( -> e { 3 } ).call(e) }).call(e) }) }).call(e); end; e }"
# >> eval(statement.to_ruby).call( x: 1)
# => {:x=>9}


	# また、このパーサは右結合なので、たとえば 1*2*3*4 は 1 * (2 * (3 * 4)) と構文解析される。

	# >> expression = SimpleParser.new.parse('1 * 2 * 3 * 4', root: :expression).to_ast
	# => «1 * 2 * 3 * 4»
	# >> expression.left
	# => «1»
	# >> expression.right
	# => «2 * 3 * 4»


# 掛け算ではこれでも正しく動作するが、引き算などでは、右結合と左結合で結果が異なる。
# これを修正するには、規則と#to_astをもっと複雑にしなければならない。
# 左結合の抽象構文木はは6章で行う。

# SIMPLEプログラムを構文解析するのは便利だが、これは大変なことはTreetopが全てやってくれたので、
# 実際はパーサがどのように機能するのかあまり学んでいない。
# パーサを直接実装するにはどうすればよいのかは4章で行う。