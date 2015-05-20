# ビッグステップ意味論 #

require "./statement_script.rb"

# スモールステップ意味論:仮想マシンは繰り返し簡約ステップすることが必要
#
# 全体を実行することが難しい複雑なプログラム
#                   ↓
# 説明や分析が簡単なより小さいかけら
# 
# 利点ではあるが遠回しでわかりづらい

# もっと直接的に文を説明したい
# →→ビッグステップ意味論
#
# どのように式や文から直接結果を得るかを明示すること
#
# 「大きな式を評価するために全ての小さな部分式を評価して、
# それからそれらの結果を合成して結果を得る」


# 実行するための命令を明示する事無しで実行する部分コンピュテーション
# というゆるいスタイルで書かれる

# スモールステップ意味論は状態の経過を追い、簡約を繰り返し実行するため
# Machine classが必要だった
# ビッグステップは
# 一回の施行で抽象的な構文木を歩くことによってプログラム全体の結果を計算
# なので扱うべき状態や実行する繰り返しがない
# よってMachineクラス不要
#
# じゃあどうするのか？
# →→ただevaluateメソッドを式や文のクラスに定義し呼び出すだけ


# 式について
# ビッグステップ意味論ではすべての式は評価可能
# 自身をすぐに評価できる式と計算を実行して異なる式を評価する式

# NumberやBooleanクラスのビッグステップのルールは
# 値はすぐに自身を評価する

class Number
  def evaluate(environment)
    self
  end
end

class Boolean
  def evaluate(environment)
    self
  end
end

# ビッグステップのルールではVariable式は 環境内の変数を見てそしてその値を返す

class Variable
  def evaluate(environment)
    environment[name]
  end
end

# 二項式Add,Multiply,LessThanは両方の値を合成する前に
# 左右の部分式を再帰的に評価する必要がある

class Add
  def evaluate(environment)
    Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
  end
end

class Multiply
  def evaluate(environment)
    Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
  end
end

class LessThan
  def evaluate(environment)
    Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
  end
end


Number.new(23).evaluate({})
Variable.new(:x).evaluate({ x: Number.new(23) })
LessThan.new(
  Add.new(Variable.new(:x),Number.new(2)),
  Variable.new(:y)
).evaluate({ x: Number.new(2), y: Number.new(5) })


# 文
# この意味論の肝は文
# ビッグステップ意味論の評価を、文と初期の環境を
# 最終的な環境に変えるプロセスとして考えることができる

# 代入文のビッグステップ評価は式を完全に評価して
# 結果の値を含む更新された環境を返す

class Assign
  def evaluate(environment)
    environment.merge({ name => expression.evaluate(environment) })
  end
end

# 同じようにDoNothingのevaluateメソッドは明らかに変更されてない環境を返し、
# Ifのevaluateメソッドは状態を評価し、帰結か代替のどちらかの評価結果を結果とする
# 環境を返す、というとても簡単な仕事です

class DoNothing
  def evaluate(environment)
    environment
  end
end

class If
  def evaluate(environment)
    case condition.evaluate(environment)
      when Boolean.new(true)
        consequence.evaluate(environment)
      when Boolean.new(false)
        alternative.evaluate(environment)
    end
  end
end

# シーケンス文では私達はただ両方の文を評価する必要があるだけですが、
# 一つ目の文の評価結果は二つ目の文が評価される環境となります。


class Sequence
  def evaluate(environment)
    second.evaluate(first.evaluate(environment))
  end
end

# 環境をスレッド化することは変数を準備するための文をより簡単にさせる

statement =
Sequence.new(
  Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
  Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
)

statement.evaluate({})

# 《while》文のためのループの評価段階
# ・状態を真か偽のどちらかを得るように評価する
# ・もし状態が真に評価されたら、新しい環境を得るために中身を評価し、
# 　それからその新しい環境でループを繰り返す（while文全体を再び評価する）
# ・もし状態が偽に評価されたら、変更されてない環境を返す

class While
  def evaluate(environment)
    case condition.evaluate(environment)
      when Boolean.new(true)
        evaluate(body.evaluate(environment))
      when Boolean.new(false)
        environment
    end
  end
end

# whileクラスのevaluateメソッドの入れ子(ネスト)を,
# 状態が偽になって最終的な環境が返されるまで
# たくさんスタックするかもしれないということ
#
# スモールステップ意味論をチェックするために使ったのと同じwhile文を評価

statement =
While.new(
  LessThan.new(Variable.new(:x), Number.new(5)),
  Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
)

statement.evaluate({ x: Number.new(1) })
