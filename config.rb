#! ruby -Ku

=begin
 2016/01/17
 共通のパスとかだけまとめたファイル
=end

require "fileutils"
require "CSV"
require "json"

#読み込ませるファイル（仮）
PATH_SOURCE_SHUTUBAHYO = "./source/sample_shutubahyo_20160108.csv"

#対戦型のスコアと勝率の分布が入ったもの。ダミーデータが入っている
PATH_SOURCE_MINING_INDEX = "./source/sample_taisen_mining_score.json"
DATA_MINING_INDEX = open(PATH_SOURCE_MINING_INDEX) do |io|
	JSON.load(io)
end

#仮想支持率をまとめたもの
PATH_JSON_INDEX_VIRTUAL_SIJI = "./source/index_virtual_siji.json"
DATA_JSON_INDEX_VIRTUAL_SIJI = open(PATH_JSON_INDEX_VIRTUAL_SIJI) do |io|
	JSON.load(io)
end

#targetで出力したものはshift_jisだから、utfにしておく
def read_csv(file_path_csv)
	data_csv = CSV.read(file_path_csv, encoding: "Shift_JIS:UTF-8")
	
	return data_csv
end

#ブログ村のトラックバック先。
#たぶんここでしか使わないので、この中に
TRACKBACKLIST = <<URL
http://horserace.blogmura.com/rpc/trackback/76822/swm4mb2smes5
http://horserace.blogmura.com/rpc/trackback/74447/swm4mb2smes5
http://horserace.blogmura.com/rpc/trackback/76272/swm4mb2smes5
URL