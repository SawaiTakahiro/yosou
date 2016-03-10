#! ruby -Ku

=begin
 2016/03/08
 対戦型マイニング予測で、馬をピックアップ→targetに取り込むためのファイル生成するスクリプト
=end

=begin
	やること
	
	基となるcsvファイルを読み込む
	レースごとに、対戦型がいい感じの馬を抜き出す
		対戦型が70以上
		下との差が10以上
		※偏差値に換算して、～以上ならっていう形もありかもしれない
	それをテキストに保存する
		レースID, "☆"
		とかかな？
=end

require "./config.rb"
require "./read_csv.rb"



############################################################
#Arrayクラスのカスタム
#http://unageanu.hatenablog.com/entry/20090312/1236862932	より
class Array
	# 要素をto_iした値の平均を算出する
	def avg
		inject(0.0){|r,i| r+=i.to_i }/size
	end
	# 要素をto_iした値の分散を算出する
	def variance
		a = avg
		inject(0.0){|r,i| r+=(i.to_i-a)**2 }/size
	end
	# 要素をto_iした値の標準偏差を算出する
	def standard_deviation
		Math.sqrt(variance)
	end
end

############################################################

data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)
kaisai = Kaisai.new(data_csv)

list_raceid = kaisai.list_raceid
hoge = list_raceid[0]

shutubahyo = kaisai.get_shutubahyo(hoge).shutubahyo

list_taisen_yosoku = Array.new
temp = Array.new
shutubahyo.map do |shussouma|
	raceid = shussouma.uma_raceid
	taisen_yosoku = shussouma.uma_taisen_yosoku
	
	list_taisen_yosoku << [raceid, taisen_yosoku]
	
	temp << taisen_yosoku
end

stdev = temp.standard_deviation
average = temp.avg

#偏差値を求めたりして、リストにする
list_hensachi = Array.new

list_taisen_yosoku.map do |raceid, taisen_yosoku|
	hensachi = ((taisen_yosoku.to_f - average) * 10 / stdev).round(2) + 50
	
	list_hensachi << [raceid, taisen_yosoku, hensachi]
end

#テスト用表示
list_hensachi.sort{|a, b| b[2]<=>a[2]}.map{|hoge| p hoge}

