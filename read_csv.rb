#! ruby -Ku

=begin
 2016/01/08
 CSVファイルを読み込むスクリプト
=end

require "fileutils"
require "CSV"
require "json"

PATH_SORCE_SHUTUBAHYO = "./source/sample_shutubahyo_20160108.csv"

#targetで出力したものはshift_jisだから、utfにしておく
def read_csv(file_path_csv)
	data_csv = CSV.read(file_path_csv, encoding: "Shift_JIS:UTF-8")
	
	return data_csv
end

hoge = read_csv(PATH_SORCE_SHUTUBAHYO)
hoge.each do |a|
	p a
end
