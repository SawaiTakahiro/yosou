#! ruby -Ku

=begin
 2016/01/08
 CSVファイルを読み込むスクリプト
=end

require "fileutils"
require "CSV"
require "json"


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

##################################################
#CSVファイル１行分のデータ
#これが複数集まったものが出馬表
class Data_shussouma
	attr_reader :uma_raceid_no_num, :uma_name, :uma_taisen_yosoku, :uma_virtual_sijiritu, :uma_odds, :uma_umaban, :uma_taisen_rank, :uma_basho, :uma_race_num, :uma_text_umamei
	
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
		@uma_text_umamei	= add_text_umamei(@uma_umaban, @uma_name)	#ほぼ出力用馬名
		
		#仮想オッズを求めるための支持率
		#検索するために、小数点以下を切り捨てて、文字列にする
		taisen_score = @uma_taisen_yosoku.to_i.to_s
		@uma_virtual_sijiritu = DATA_JSON_INDEX_VIRTUAL_SIJI[taisen_score]
	end
	
	def add_virtual_odds(odds)
		@uma_odds = odds
	end
	
	#馬番と馬名を返す
	#ブログの記事用ににたようなメソッド作ったけど、そもそも出走馬で持った方が便利だった
	def add_text_umamei(umaban, uma_name)
		text = Array.new
		
		text << format("%02d",umaban) + "番" + uma_name
		
		return text
	end
	
	#てすと用
	def test
		#p self
		#p @uma_raceid
		#p @uma_raceid_no_num
	end
end

#出馬表
class Data_shutubahyo
	attr_reader :shutubahyo, :taisen_rank
	
	def initialize(source)
		@shutubahyo = Array.new
		
		source.each do |raceid, shussouma|
			#レースIDの方は出走馬自体に含んでいるから足さない。
			@shutubahyo << shussouma
		end
		
		@taisen_rank = Taisen_rank.new(@shutubahyo)
		
		#出馬表が決まったら、仮想オッズも求めておく
		add_virtual_odds
	end
	
	#仮想オッズを求める
	#対戦型マイニング予測のスコアごとに仮想支持率を求め、それをオッズに換算する
	def add_virtual_odds
		#支持の強さ合計を求めておく
		total_siji = 0
		@shutubahyo.each do |shussouma|
			siji = shussouma.uma_virtual_sijiritu
			total_siji += siji
		end
		
		#支持率を求める
		@shutubahyo.each do |shussouma|
			siji = shussouma.uma_virtual_sijiritu
			
			total_hyosu = 10000	#仮の投票数。それ自体はいくつでも良い
			rate = siji / total_siji
			
			#単勝オッズの計算式は、JRAにある通り
			odds = ((total_hyosu * 0.8) / (total_hyosu * rate)).round(1)
			
			shussouma.add_virtual_odds(odds)
		end
	end
	
	
	
	def test
		@shutubahyo.each do |shussouma|
			#p shussouma.instance_variables
			p shussouma.uma_odds
		end
	end
end

#今日のレースまとめ。１日単位だけど開催ってしておく
#出馬表をまとめたもの
class Kaisai
	attr_reader :list_raceid, :list_basho
	
	def initialize(data_csv)
		@source = to_source(data_csv)
		@list_raceid = get_list_raceid(@source)
		@list_basho = get_list_basho(@source)
		
		@kaisai = Hash.new
		
		@list_raceid.each do |id|
			add_kaisai(id, @source)
		end
	end
	
	#その日に行われるレースidのリストを作る
	def get_list_raceid(source)
		temp = Array.new
		source.each do |id, shussouma|
			temp << shussouma.uma_raceid_no_num
		end
		
		return temp.uniq
	end
	
	#いくつのコースで開催されてるかリスト。
	def get_list_basho(source)
		temp = Array.new
		source.each do |id, shussouma|
			id = shussouma.uma_raceid_no_num
			temp << id[0..11]
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
		#レースIDに対応した出走馬だけ抜き出す
		temp_source = get_temp_source(id, source)
		shutubahyo = Data_shutubahyo.new(temp_source)
		
		@kaisai.store(id, shutubahyo)
	end

	def test
		@source.each do |id, shussouma|
			p shussouma.uma_raceid_no_num
		end
	end
	
	def get_shutubahyo(raceid)
		return @kaisai[raceid]
	end
end



=begin
 対戦ランクS〜Dのそれぞれ数（対戦型マイニング予測のスコアで分けている）
 実力馬の割合
 混戦度合い
 を持たせる…のは今度
=end
class Taisen_rank
	attr_reader :count_rank_all, :count_rank_s, :count_rank_a, :count_rank_b, :count_rank_c, :count_rank_d
	
	def initialize(shutubahyo)
		list_taisen_score = get_list_taisen_score(shutubahyo)
		
		@count_rank_all = shutubahyo.length
		
		#ランクわけの基準値
		#80より大だとSランク
		kijun_a = 80
		kijun_b = 70
		kijun_c = 60
		kijun_d = 50
		
		@count_rank_s = list_taisen_score.select{|score| score > kijun_a}.length
		@count_rank_a = list_taisen_score.select{|score| score <= kijun_a &&  score > kijun_b}.length
		@count_rank_b = list_taisen_score.select{|score| score <= kijun_b &&  score > kijun_c}.length
		@count_rank_c = list_taisen_score.select{|score| score <= kijun_c &&  score > kijun_d}.length
		@count_rank_d = list_taisen_score.select{|score| score <= kijun_d}.length
		
		#実力馬（Bランク以上の馬）の割合
		jituryokuuma = @count_rank_s + @count_rank_a + @count_rank_b
		@rate_jituryokuuma = jituryokuuma / @count_rank_all.to_f
		
		
		
		
	end
	
	#扱いやすいように、対戦型のスコアだけ抜き出してまとめちゃう
	def get_list_taisen_score(shutubahyo)
		temp = Array.new
		shutubahyo.each do |shussouma|
			temp << shussouma.uma_taisen_yosoku
		end
		
		return temp
	end
	
	
	def test
		p @count_rank_all
		p @count_rank_s
		p @count_rank_a
		p @count_rank_b
		p @count_rank_c
		p @count_rank_d
	end
	
	
end
