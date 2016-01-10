#! ruby -Ku

=begin
 2016/01/10
 ブログに投稿する用のテキストを生成するスクリプト
 
=end

require "fileutils"
require "CSV"
require "json"

require "./read_csv.rb"
require "./yosou.rb"

=begin
 メモ：
 ブログの本文っていうクラスがあってもよさそう。
 レース単位で加工したものもそれぞれクラスにしちゃうとか。
 →それを統合してブログ本文とかして、出力しちゃう。
 
 まずは、レース単位で処理する部分を作る
=end

#予想と同じく、出馬表クラスを使ってあれこれする
class Text_race
	def initialize(shutubahyo, yosou)
		@shutubahyo			= shutubahyo.shutubahyo	#出馬表クラスの出馬表
		@taisen_rank		= shutubahyo.taisen_rank
		
		@raceid_no_num		= yosou.raceid_no_num
		@yosou_umaban		= yosou.yosou_umaban
		@deployment_umaban	= yosou.deployment_umaban
		@kaime				= yosou.kaime
		
	end
	
	#馬番と馬名を返す
	def get_text_umamei(umaban, shutubahyo)
		text = Array.new
		
		name_uma = @shutubahyo[umaban - 1].uma_name
		
		text << format("%02d",umaban) + "番" + name_uma
		
		return text
	end
	
	#対戦型の分布
	def get_text_bunpu_taisen_rank(taisen_rank)
		#この中でしか使わないやつ。こういう使い方ってアリなの？
		def get_rate_taisen_rank(base, total)
			value = (base * 1.0) / total
			
			return (value * 100).round(2).to_s + "%"
		end
		
		text = Array.new
		
		#割合に直したものもあらかじめ用意しておく
		rate_rank_s = get_rate_taisen_rank(@taisen_rank.count_rank_s, @taisen_rank.count_rank_all)
		rate_rank_a = get_rate_taisen_rank(@taisen_rank.count_rank_a, @taisen_rank.count_rank_all)
		rate_rank_b = get_rate_taisen_rank(@taisen_rank.count_rank_b, @taisen_rank.count_rank_all)
		rate_rank_c = get_rate_taisen_rank(@taisen_rank.count_rank_c, @taisen_rank.count_rank_all)
		rate_rank_d = get_rate_taisen_rank(@taisen_rank.count_rank_d, @taisen_rank.count_rank_all)
		
		text << "▽対戦型予測の分布："
		text << "Sランク：" + @taisen_rank.count_rank_s.to_s + "頭　" + rate_rank_s
		text << "Aランク：" + @taisen_rank.count_rank_a.to_s + "頭　" + rate_rank_a
		text << "Bランク：" + @taisen_rank.count_rank_b.to_s + "頭　" + rate_rank_b
		text << "Cランク：" + @taisen_rank.count_rank_c.to_s + "頭　" + rate_rank_c
		text << "Dランク：" + @taisen_rank.count_rank_d.to_s + "頭　" + rate_rank_d
		
		return text
	end
	
	def test
		#puts get_text_bunpu_taisen_rank(@taisen_rank)
		#p get_text_umamei(1, @shutubahyo)
	end
end


############################################################
data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)
kaisai = Kaisai.new(data_csv)
list_raceid = kaisai.list_raceid

shutubahyo = kaisai.get_shutubahyo("RX2016010906010201")

yosou = Yosou.new(shutubahyo)
hoge = Text_race.new(shutubahyo, yosou)
hoge.test