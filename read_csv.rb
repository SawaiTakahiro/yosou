#! ruby -Ku

=begin
 2016/01/08
 CSVファイルを読み込むスクリプト
=end

require "fileutils"
require "CSV"
require "json"

PATH_SORCE_SHUTUBAHYO = "./source/sample_shutubahyo_20160108.csv"

#CSVファイル１行分のデータ
#これが複数集まったものが出馬表
class Data_shussouma
	attr_reader :uma_raceid_no_num, :uma_name
	
	#CSVを読み込み、１行ずつ渡される
	#配列形式で渡されるはず
	def initialize(record)
		#元のデータが全部文字で入っているので、数値系は変換しておく
		@uma_basho			= record[0]
		@uma_race_num		= record[1].to_i
		@uma_class			= record[2]
		@uma_category		= record[3]
		@uma_kyori			= record[4].to_i
		@uma_umaban			= record[5].to_i
		@uma_name			= record[6]
		@uma_time_yosoku	= record[7].to_f	#タイム型、対戦型の予測値は小数がある
		@uma_time_rank		= record[8].to_i
		@uma_taisen_yosoku	= record[9].to_f
		@uma_taisen_rank	= record[10].to_i
		@uma_raceid			= record[11]			#馬番有り＝全データでユニーク
		@uma_raceid_no_num	= @uma_raceid[0..17]	#馬番抜き＝レースごとにユニーク
	end
	
	#てすと用
	def test
		#p self
		p @uma_raceid
		#p @uma_raceid_no_num
	end
	
	
	
end

#targetで出力したものはshift_jisだから、utfにしておく
def read_csv(file_path_csv)
	data_csv = CSV.read(file_path_csv, encoding: "Shift_JIS:UTF-8")
	
	return data_csv
end

hoge = read_csv(PATH_SORCE_SHUTUBAHYO)

source = Array.new
hoge.each do |data|
	temp = Data_shussouma.new(data)
	
	#馬番なしレースIDをキーにした配列で入れておく
	#レース単位で分けるため
	source << [temp.uma_raceid_no_num, temp]
	
end

source.each do |raceid, shussouma|
	p raceid + shussouma.uma_name
end