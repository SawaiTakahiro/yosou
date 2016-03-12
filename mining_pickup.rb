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

require "CSV"
require "./config.rb"
require "./read_csv.rb"



############################################################
#Arrayクラスのカスタム
#http://unageanu.hatenablog.com/entry/20090312/1236862932	より
class Array
	# 要素をto_iした値の平均を算出する
	def avg
		inject(0.0){|r,i| r+=i.to_f }/size
	end
	# 要素をto_iした値の分散を算出する
	def variance
		a = avg
		inject(0.0){|r,i| r+=(i.to_f-a)**2 }/size
	end
	# 要素をto_iした値の標準偏差を算出する
	def standard_deviation
		Math.sqrt(variance)
	end
end

############################################################

def test(shutubahyo)
	#対戦型が提供されていないレースだったら、そこで抜ける
	yosoku = shutubahyo[0].uma_taisen_yosoku
	return if yosoku == 0
	
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
	
	output = Array.new
	list_taisen_yosoku.map do |raceid, taisen_yosoku|
		hensachi = ((taisen_yosoku.to_f - average) * 10 / stdev).round(2) + 50
		list_hensachi << [raceid, taisen_yosoku, hensachi]
		
		#値が一定以上のものだけ厳選する
		if hensachi >= 65 then
			output << [raceid, "A"]
		elsif hensachi >= 60 then
			output << [raceid, "B"]
		end
	end

	#テスト用表示
	#list_hensachi.sort{|a, b| b[2]<=>a[2]}.map{|hoge| p hoge}
	return output
end

#data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)
data_csv = read_csv("./source/対戦型マイニング予測blog出力用.csv")
kaisai = Kaisai.new(data_csv)

list_raceid = kaisai.list_raceid

list_gensen = Array.new
list_raceid.each do |raceid|
	shutubahyo = kaisai.get_shutubahyo(raceid).shutubahyo
	data = test(shutubahyo)
	list_gensen += data if data != nil
end

#暫定の出力用
list_gensen.map{|id, rank| print "#{id},#{rank}\n"}