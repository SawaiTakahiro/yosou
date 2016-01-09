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
		p self
		#p @uma_raceid
		#p @uma_raceid_no_num
	end
end

#出馬表
class Data_shutubahyo
	def initialize(source)
		@shutubahyo = Array.new
		
		source.each do |raceid, shussouma|
			#レースIDの方は出走馬自体に含んでいるから足さない。
			@shutubahyo << shussouma
		end
	end
	
	def test
		@shutubahyo.each do |shussouma|
			p shussouma.uma_name
		end
	end
end

#今日のレースまとめ。１日単位だけど開催ってしておく
#出馬表をまとめたもの
class Kaisai
	attr_reader :list_raceid
	
	def initialize(data_csv)
		@source = to_source(data_csv)
		@list_raceid = get_list_raceid(@source)
		
		@kaisai = Hash.new
		
		id = "RX2016010906010212"
		add_kaisai(id, @source)
	end
	
	#その日に行われるレースidのリストを作る
	def get_list_raceid(source)
		temp = Array.new
		source.each do |id, shussouma|
			temp << shussouma.uma_raceid_no_num
		end
		
		return temp.uniq
	end
	
	#レースID,出走馬って形のものに
	#データはとりあえず、出走馬形式にしておく
	#そのほうが中身を扱いやすいし
	def to_source(data_csv)
		temp = Array.new
		
		data_csv.each do |record|
			shussouma = Data_shussouma.new(record)
			raceid_no_num = shussouma.uma_raceid_no_num
			
			temp << [raceid_no_num, shussouma]
		end
		
		return temp
	end
	
	#ソースデータから、そのレースIDの出走馬だけ抜き出す
	#出走馬クラスを作るために使う
	def get_temp_source(id, source)
		temp = Array.new
		
		#当該レースIDの馬を抜き出す => レースごと出走馬一覧
		#この時点では、sourceと同じ。raceid, 出走馬クラスという形
		temp_source = source.select{|raceid, shussouma| raceid == id}
		
		return temp_source
	end
	
	#出馬表クラスを作って、開催に足していく
	def add_kaisai(id, source)
		#レースIDに対応した出走馬だけ抜き出して、
		temp_source = get_temp_source(id, source)
		fuga = Data_shutubahyo.new(temp_source).test
		#fuga.test
	end

	def test
		@source.each do |id, shussouma|
			p shussouma.uma_raceid_no_num
		end
	end
	
end

=begin
 メモ：覚書
 csvファイルを読み込む
 で、それを加工してあれこれしたい
 
 なんか、読み込んだcsvファイル（Array）を開催クラスに投げると、
 その中でクラスとか作れそうな気がする
 
 頭の中を整理したほうがいいかも
=end


#targetで出力したものはshift_jisだから、utfにしておく
def read_csv(file_path_csv)
	data_csv = CSV.read(file_path_csv, encoding: "Shift_JIS:UTF-8")
	
	return data_csv
end

##################################################
hoge = read_csv(PATH_SORCE_SHUTUBAHYO)

kaisai = Kaisai.new(hoge)
#puts kaisai.list_raceid


=begin
source = Array.new
hoge.each do |data|
	temp = Data_shussouma.new(data)
	
	#馬番なしレースIDをキーにした配列で入れておく
	#レース単位で分けるため
	source << [temp.uma_raceid_no_num, temp]
	
end
=end
=begin
source.each do |raceid, shussouma|
	p raceid + shussouma.uma_name
end
=end

=begin
id = "RX2016010908010211"	#テスト用
hoge = source.select{|raceid, shussouma| raceid == id}

fuga = Data_shutubahyo.new
hoge.each do |raceid, shussouma|
	#shussouma.test
	#fuga.add_shussouma(shussouma)
	p shussouma.instance_variables
	break
end

#fuga.test
=end

