#! ruby -Ku

=begin
 2016/01/09
 予想処理のスクリプト
 
 予想自体をクラスにした。
 出馬表クラスを渡されると、予想して買い目を作ったりする。
=end

require "fileutils"
require "CSV"
require "json"

require "./config.rb"

require "./read_csv.rb"

#馬券の種類。targetの買い目データ準拠
BAKEN_TANSHO		= 0
BAKEN_FUKUSHO		= 1
BAKEN_WAKUREN		= 2
BAKEN_UMAREN		= 3
BAKEN_WIDE			= 4
BAKEN_UMATAN		= 5
BAKEN_SANRENFUKU	= 6
BAKEN_SANRENTAN		= 7


#予想した結果の馬番を入れるクラス
#ブログの記事にするときに使っている
#本命、対抗、ヒモを持つ
#本命、対抗は１頭ずつなのでそのまま値、ヒモは何頭いるかわからないので配列に馬番が入っている形にしている
#本命、対抗とはいうけど、実際には特に優劣なく軸A/Bとして扱っている
class List_yosou_umaban
	attr_reader :jiku_a, :jiku_b, :himo
	
	def initialize(jiku_a, jiku_b, himo)
		@jiku_a = jiku_a
		@jiku_b = jiku_b
		@himo	= himo.sort
	end
	
end

#予想クラス
#デフォルトで、適当な三連単を生成している
#オーバーライドして適宜、予想の中身をつくれば良いはず？
#出馬表クラスを受け取ってあれこれする
class Yosou
	attr_reader :raceid_no_num, :yosou_umaban, :deployment_umaban, :kaime, :error
	def initialize(data)
		@error = false	#無効なデータか否か。true : ダメなデータ、false : 問題ないデータ
		
		#もし、対戦型予測が提供されていなそうなら、そこで終了する
		taisen_yosoku = data.shutubahyo[0].uma_taisen_yosoku
		if taisen_yosoku == 0 then
			@error = true	#データ的にはエラーとしておく
			return
		end
		
		@raceid_no_num = get_raceid_no_num(data)
		
		#予想、買い目の展開の仕方はそれ用のメソッドで
		#yosouの中を書き換えるだけで良いはず
		yosou(data)
	end
	
	def get_raceid_no_num(data)
		shutubahyo = data.shutubahyo
		raceid_no_num = shutubahyo[0].uma_raceid_no_num
		
		return raceid_no_num
	end
	
	#他の予想方法を使ったりする場合は、このメソッドを書き換える
	#返り値とかはなし。そのまま、インスタンス変数を作っちゃう。
	def yosou(data)
		@yosou_umaban = get_yosou_sanrentan(data)
		@deployment_umaban = get_deployment_umaban_sanrentan_2m(@yosou_umaban)
		@kaime = get_kaime_target(@raceid_no_num, @deployment_umaban, BAKEN_SANRENTAN)
	end
	
	#予想した馬番だけ取得する
	#予想の方法ごとに、馬券の種類ごとに中身は変わる
	#ただ、出馬表クラスを入れて、予想クラス（List_yosou_umaban）を返すのは同じ
	def get_yosou_sanrentan(data)
		#出馬表クラスから、出走馬が入っている部分だけ取り出す
		shutubahyo = data.shutubahyo
		
		#対戦予測が提供されていないレースなら抜ける
		if shutubahyo[0].uma_taisen_yosoku == 0 then
			return
		end
		
		#以降が予想部分になる	########################################
		#仮で適当な馬を選んでいる
		tousu = shutubahyo.length
		
		#対戦型マイニング順の馬番リストを用意する
		#買い目の生成は、それによるところが多いので。
		temp_umaban = Array.new
		shutubahyo.each do |shussouma|
			uma_umaban = shussouma.uma_umaban
			uma_taisen_rank = shussouma.uma_taisen_rank
			
			#この作り方だと、同じ順位があったときnilな値が出てきてエラーになる
			#list_taisen_rank[uma_taisen_rank - 1] = uma_umaban
			
			temp_umaban << [uma_taisen_rank, uma_umaban]
		end
		
		#面倒かもしれないけど、対戦型、馬番だけ抜き出したリストを作って、それをソートして、馬番だけ取り出す
		list_taisen_rank = Array.new
		temp_umaban.sort.each do |rank, umaban|
			list_taisen_rank << umaban
		end
		
		umaban_honmei = list_taisen_rank[0]
		umaban_taikou = list_taisen_rank[1]
		umaban_himo = list_taisen_rank[2..5]
		
		#ここまでが予想部分		########################################
		
		
		list_yosou_umaban = List_yosou_umaban.new(umaban_honmei, umaban_taikou, umaban_himo)
		
		return list_yosou_umaban
	end
	
	#予想した馬番を展開する
	#三連単２頭軸マルチ※ヒモ１着パターンは削った版
	#1, 2, 3って感じで３頭１セットが配列で返ってくる
	def get_deployment_umaban_sanrentan_2m(list_yosou_umaban)
		umaban_honmei	= list_yosou_umaban.jiku_a
		umaban_taikou	= list_yosou_umaban.jiku_b
		umaban_himo		= list_yosou_umaban.himo
		
		temp_umaban = Array.new
		umaban_himo.each do |himo|
			temp_umaban << [umaban_honmei, umaban_taikou, himo]
			temp_umaban << [umaban_honmei, himo, umaban_taikou]
			
			temp_umaban << [umaban_taikou, umaban_honmei, himo]
			temp_umaban << [umaban_taikou, himo, umaban_honmei]
			
			#これは削っている
			#完全にマルチにする場合は必要。あってもあんま当たらないから省いた方が良さげ
			#list_umaban_kaime << [himo, umaban_honmei, umaban_taikou]
			#list_umaban_kaime << [himo, umaban_taikou, umaban_honmei]
		end
		
		return temp_umaban
	end
	
	#ターゲット用の買い目を生成して返す
	#配列で返す。１要素１買い目って形
	#金額は100円にしている。
	def get_kaime_target(raceid_no_num, list_yosou_umaban, baken_id)
		kaime = Array.new
		
		list_yosou_umaban.sort.each do |a, b, c|
			temp = to_kaime(raceid_no_num, baken_id, a, b, c, 100)
			kaime << temp
		end
		
		return kaime
	end
	
	#１つの買い目を生成する
	#http://faqnavi13a.csview.jp/faq2/userqa.do?user=jravan&faq=faq01_target&id=312&parent=20
	#レースID,返還フラグ,券種, 目１,目２,目３,購入金額,オッズ,的中時の配当, エリア,マーク,一括購入目用馬番
	#空でいいので項目は埋めてね、とのこと
	def to_kaime(raceid_no_num, category, umaban1, umaban2, umaban3, price)
		temp = Array.new
		temp << raceid_no_num
		temp << 0	#返還フラグ。0を入れてねとのこと
		temp << category	#馬券の種類
		temp << umaban1
		temp << umaban2
		temp << umaban3
		temp << price
		temp << 0	#オッズ
		#temp << 0	#的中時の配当
		temp << "A"	#エリア
		temp << ""	#一括購入用馬番
		
		return temp
	end
	
	def test
		p self
	end
end
