#! ruby -Ku

=begin
 2016/01/16
 厳選馬をピックアップするスクリプト
 出馬表じゃなく、開催単位でデータを探していくはずなので予想とは別ロジックになるはず。
=end

require "fileutils"
require "CSV"
require "json"

require "./read_csv.rb"

#出馬表データから、対戦型予測が50以上の馬だけ抜き出して返す
#対戦型で50以下はまず用無しなので削っちゃう
def ashikiri(data_csv)
	pickup = data_csv.select do |record|
		race_num = record[9].to_i
		race_num >= 50
	end
	
	return pickup
end

############################################################
#読み込ませるファイル（仮）
PATH_SOURCE_SHUTUBAHYO = "./source/sample_shutubahyo_20160108.csv"
data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)

pickup = ashikiri(data_csv)

#スコア順に並べたものを別途用意する
temp = pickup.sort{|a, b| b[9].to_i <=> a[9].to_i}

temp[0, 5].each do |hoge|
	Data_shussouma.new(hoge)
end