#! ruby -Ku

=begin
 2016/01/16
 厳選馬をピックアップするスクリプト
 出馬表じゃなく、開催単位でデータを探していくはずなので予想とは別ロジックになるはず。
=end

require "fileutils"
require "CSV"
require "json"

require "./config.rb"

require "./read_csv.rb"

#厳選馬。それ自体をクラスに
#いろいんな条件で抽出したshussoumaクラスの配列を持っている
#配列の種類はいろいろ増やしてみる
class Gensen_uma
	attr_reader :pickup_list_score, :pickup_list_okaidoku, :text_title
	
	def initialize(data_csv)
		@text_title 			= get_date(data_csv)
		
		#それぞれの条件でピックアップしていく
		@pickup_list_score		= pickup_score(data_csv)
		@pickup_list_okaidoku	= pickup_okaidoku(data_csv)
	end
	
	#日付の取得をする
	#ブログの記事に使うだけなので、日付自体は文字列。
	def get_date(data_csv)
		#作業用に適当なデータで出走馬を作る
		temp_shussouma	= Data_shussouma.new(data_csv[0])
		raceid_no_num	= temp_shussouma.uma_raceid_no_num
		
		year	= raceid_no_num[2..5]
		month	= raceid_no_num[6..7]
		day		= raceid_no_num[8..9]
		
		#「2016/01/11京都の対戦型データマイニング予測ピックアップ」とかって形
		return year + "/" + month + "/" + day + "の厳選馬"
	end
	
	#仮想複勝オッズを求めるメソッド
	#仮想の単勝オッズ / 2して、それの平方根を求めるとそれっぽい気がする？
	#１レコード分だけ処理して返す。必要になったらその都度呼ぶ感じ
	def get_virtual_odds_fukusho(odds)
		return Math.sqrt(odds / 2)
	end
	
	#出馬表データから、対戦型予測が50以上の馬だけ抜き出して返す
	#対戦型で50以下はまず用無しなので削っちゃう
	#やっぱり、どこで切るか？は引数でもてる方にした方がよさそう
	def ashikiri(data_csv, rate)
		pickup = data_csv.select do |record|
			race_num = record[9].to_i
			race_num >= rate
		end
		
		return pickup
	end
	
	#対戦型スコアが上位の馬だけを抜き出して返す
	def pickup_score(data_csv)
		#スコアが80以上のものだけピックアップ
		pickup = ashikiri(data_csv, 80)
		
		max = pickup.length
		#たくさんいた場合は上位5頭までにまとめる
		if max > 5 then
			max = 5
		end
		
		
		#対戦型のスコア順に並べる
		sort_pickup = pickup.sort{|a, b| b[9].to_i <=> a[9].to_i}
		
		temp = Array.new
		sort_pickup[0..max].each do |record|
			temp << Data_shussouma.new(record)
		end
		
		return sort_list_shussouma(temp)
	end
	
	#オッズがお買い得な馬をピックアップ
	def pickup_okaidoku(data_csv)
		#１回、開催データを作ってから加工し直す
		kaisai = Kaisai.new(data_csv)
		#puts kaisai.instance_variables
		
		list_shussouma = kaisai.get_list_shussouma	#その日に出る馬の一覧
		
		#条件に合う馬だけ抜き出して出力する
		temp = Array.new
		list_shussouma.each do |shussouma|
			#対戦予測が50未満なら飛ばす
			taisen_yosoku = shussouma.uma_taisen_yosoku
			next if taisen_yosoku < 50
			
			#複勝率はあるていど欲しい
			#参照先のキーが整数でしかも文字列だからごにょごにょしてる
			fukusho = DATA_MINING_INDEX[taisen_yosoku.to_i.to_s]["fukusho"]
			next if fukusho < 0.5
			
			#仮想複勝オッズを求めて判断。求め方は適当だけど…
			#仮想複勝オッズ自体は記事に盛り込まないので、ここだけで使う
			virtual_odds_fukusho = get_virtual_odds_fukusho(shussouma.uma_odds)
			next if virtual_odds_fukusho < 1.5
			
			#残ったものだけリストに追加
			temp << shussouma
		end
		
		return sort_list_shussouma(temp)
	end
	
	#出走馬が入ったリストを、レースID順に並べて返す
	#そのままだとソートができないので
	def sort_list_shussouma(list_shussouma)
		temp = Array.new
		list_shussouma.each do |shussouma|
			temp << [shussouma.uma_raceid, shussouma]
		end
		
		output = Array.new
		temp.sort.each do |raceid, shussouma|
			output << shussouma
		end
	
		return output
	end
end
