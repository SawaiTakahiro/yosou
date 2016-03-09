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


data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)
kaisai = Kaisai.new(data_csv)

list_raceid = kaisai.list_raceid
hoge = list_raceid[0]

shutubahyo = kaisai.get_shutubahyo(hoge).shutubahyo

list_taisen_yosoku = Array.new
shutubahyo.map do |shussouma|
	list_taisen_yosoku << shussouma.uma_taisen_yosoku
end

puts list_taisen_yosoku

