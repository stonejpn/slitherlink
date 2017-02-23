# スリザーリンクを解くスクリプト

## 使い方

### 問題の置き方

ファイルの先頭にある`SPEC`の中身を書き換えます。
フォーマットは、`タテxヨコ:グリッド`という形式になります。

```
+   +   +   +
      0   1
+   +   +   +

+   +   +   +
  2
+   +   +   +
```

という問題では、`3x3:.01...2..`と置きます。

## 実行

解答を`console.log()`で出力しています。  
作者は、Atom Editor + scriptプラグインで実行しています。他の実行環境はよくわかりません。

問題によっては、5秒以上かかるケースがあります。実行途中で強制終了したい場合は、`Matrix.forceQuit`を`true`に変更するとすぐに終了するはずです。

例えば、`setTimeout`を利用する場合は、ファイルの一番下、`Solver.run()`の部分を以下のように書き換えればいいはずです。

```coffee
force_quit = -> Matrix.forceQuit = true
timer_id = setTimeout(force_quit, 5 * 1000)

Solver.run(SPEC.replace(/\s/g, ''))

clearTimeout(timer_id)
```

> 追記  
> 完成後、10x10のパズルをいくつか試しましたが、完了まで3分程度かかるものがありました。
> まだまだ改善の余地があるようです。

## なぜ作ったのか？

数独もいけたから、スリザーリンクもいけると思った。

----

# 実装を始める前に考えをまとめたメモ

実装とは、少し違う部分もありますが、基本はこの考え方で作っています。

## 用語を定義

各マスの構成要素を以下のように名付けます。

```
                 Line
Connector --> +---------+ <-- Connector
              |         |
         Line |   Box   | Line
              |         |
Connector --> +---------+ <-- Connector
                 Line
```

### Line

実際に解いていく線をLineと呼びます。Lineがとる値は、
* ラインが引かれている
* ラインを引くのは禁止
* 未決定

の３つです。

### Connector

LineとLineの接合点をConnectorとします。Connector自体は値を持つことはありません。

### Box

4つのLineで囲まれた四角形をBoxと呼びます。Boxの値は出題時に決まり、
* 指定されていない
* 1〜3の数値

を取ることができます。

### Matrix

問題全体をMatrixと呼ぶことにします。

## 問題の記述

問題の記述には、タテ・ヨコの大きさ、Boxの値が必要になります。
そこで、

`(ヨコ)x(タテ):(Boxの値を並べたもの)`

という書式で記述することにします。
また、値が指定されていないBoxは"."と置くことにします。

```
+   +   +   +
      0   1
+   +   +   +

+   +   +   +
  2
+   +   +   +
```

(http://f.hatena.ne.jp/myato/20110618201406 より)

上図の例では、

`3x3:.01...2..`

と記述します。

## データ構造

3x3の問題の場合、Matrixは以下のようにデータを持ちます。

```
 +---h0,1----+---h0,2----+---h0,3----+
 |           |           |           |
 |   b1,1    |   b1,2    |   b1,3    |
v1,0        v1,1        v1,2        v1,3
 |           |           |           |
 +---h1,1----+---h1,2----+---h1,3----+
 |           |           |           |
 |   b2,1    |   b2,2    |   b2,3    |
v2,0        v2,1        v2,2        v2,3
 |           |           |           |
 +---h2,1----+---h2,2----+---h2,3----+
 |           |           |           |
 |   b3,1    |   b3,2    |   b3,3    |
v3,0        v3,1        v3,2        v3,3
 |           |           |           |
 +---h3,1----+---h3,2----+---h3,3----+

```

Lineは、タテとヨコを区別し、ヨコ線は"h"、タテ線は"v"を先頭に付け、座標を付加します。
Boxでは、"b"と座標で表します。

### Peer

あるLineに注目した時に、そのLineの値(線を引く/引かない)に、相互に影響し合うLineをPeerと呼びます。

#### BoxPeer

Lineに隣接するBoxは最大で２つ。その2つのBoxを構成するLineをBoxPeerと呼ぶことにします。あるLineのBoxPeerは、それぞれのBoxで最大３つになります。

上図で、`h1,2`のBoxPeerは、
```
'b1,2': ['h0,2', 'v1,1', 'v1,2']
'b2,2': ['v2,1', 'v2,2', 'h2,2']
```

になります。

#### ConnectorPeer

Lineの両端のConnectorを共有するLineを指します。Connectorには最大4つのLineが接続するので、あるLineのConnectorPeerは、両端のConnectorでそれぞれ最大３つとなります。

上図で、`h1,2`のConnectorPeerは、
```
['h1,1', 'v1,1', 'v2,1']
['h1,3', 'v1,2', 'v2,2']
```

となります。

## 解法

### 制約

#### BoxPeer

Boxに値が指定されている場合、線が引かれているLineの数は、そのBoxの値になります。

特に、Boxの値が0の場合、そのBoxPeerでは線は引けません。

#### ConnectorPeer

どのConnectorPeer内でも、線が引かれているLineの数は0か2のみになります。線が引かれている数が、1つだけなら線が途切れていますし、3つなら枝分かれしています。

#### ループの制約

Lineに線を引いていってループが形成されたときにループの制約に照らし合わせます。ループの制約は以下のようになります。

1. すべてのBoxPeerとBoxの値に矛盾がない
2. あるLineから引かれている線を辿り、元のLineに戻ってくることができる
3. 2で辿ったLineの数が、Matrix全体で引かれているLineの数と一致する

### 総当りでの解法

問題が解けた状態から見れば、各Lineの値は、

* 線が引かれている
* 線が引かれていない

のどちらかの値しかとりません。
その為、すべてのLineについて線を引き、矛盾が生じれば、そのLineには「線は引けない」と判断します。

### 開始地点を決定

開始地点は、Boxに1〜3の値が指定されているBoxPeerから始めるのがよいでしょう。ボックスの値ごとに線が引けるパターンは

* 0: 0パターン
* 1: 4パターン
* 2: 6パターン
* 3: 4パターン

なので、優先順位は、1、3、2の順になります。(0は開始地点の決定に際しては、利用しません。)
