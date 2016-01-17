#! ruby -Ku

=begin
 2016/01/10
 ブログに投稿する用のテキストを生成するスクリプト
 
=end

require "fileutils"
require "CSV"
require "json"

require "./config.rb"

require "./read_csv.rb"
require "./yosou.rb"


#レースごとのテキストを格納する
#1〜12レースまでのテキスト
#メインレースの予想を使ったタグ、記事の概要なんかも持たせる。
#これ自体がブログの記事１つぶんって感じ
class Text_basho
	attr_reader :list_text_race, :text_title, :text_ogp, :name_honmei
	
	def initialize
		@list_text_race = Array.new
		@text_title = "ダミー。タイトルテキスト"
		@text_ogp = "ダミー。概要テキスト"
	end
	
	def add_text_race(text_race)
		@list_text_race << text_race.blog_text
	end
	
	#タイトルは、出馬表からあれこれして生成する
	#場所、日付が必要。日付はレースIDを加工して取り出す
	def add_text_title(shutubahyo)
		#適当な馬を選ぶ。場所とかは同じレースなら共通なので
		shussouma		= shutubahyo.shutubahyo[0]
		raceid_no_num	= shussouma.uma_raceid_no_num
		basho			= shussouma.uma_basho
		
		year	= raceid_no_num[2..5]
		month	= raceid_no_num[6..7]
		day		= raceid_no_num[8..9]
		
		#「2016/01/11京都の対戦型データマイニング予測ピックアップ」とかって形
		@text_title = year + "/" + month + "/" + day + basho + "の対戦型データマイニング予測ピックアップ"
	end
	
	#ブログの概要を作る
	#どのレースで概要を作るべきか？は別のところで判断する
	#この中では呼ばれたら足す（上書きする）だけ
	def add_text_ogp(text_race)
		@text_ogp = text_race.blog_ogp
	end
	def add_text_honmei(text_race)
		@name_honmei = text_race.name_honmei
	end
	
	def test
		puts @text_title
		#puts @list_text_race
		puts @text_ogp
	end
end

=begin
 メモ：
 ブログの本文っていうクラスがあってもよさそう。
 レース単位で加工したものもそれぞれクラスにしちゃうとか。
 →それを統合してブログ本文とかして、出力しちゃう。
 
 まずは、レース単位で処理する部分を作る
=end
#予想と同じく、出馬表クラスを使ってあれこれする
class Text_race
	attr_reader :blog_text, :blog_ogp, :name_honmei
	def initialize(shutubahyo, yosou)
		#エラーデータだった場合は中止
		#というか、そもそもこのクラスを作らないようにしておくほうが良い？
		if yosou.error == true then
			return
		end
		
		
		@shutubahyo			= shutubahyo.shutubahyo	#出馬表クラスの出馬表
		@taisen_rank		= shutubahyo.taisen_rank
		
		@raceid_no_num		= yosou.raceid_no_num
		@yosou_umaban		= yosou.yosou_umaban
		@deployment_umaban	= yosou.deployment_umaban
		@kaime				= yosou.kaime
		
		#ここからが、生成したもの
		@blog_text = Array.new
		
		name_race = get_name_race(@shutubahyo)
		@blog_text << "■" + name_race
		
		@blog_text << get_text_bunpu_taisen_rank(@taisen_rank).join("\n")
		@blog_text << get_text_tanpyo(@taisen_rank).join("\n")
		@blog_text << get_text_list_umamei(@yosou_umaban, @shutubahyo).join("\n")
		@blog_text << get_text_kaime_sanrentan_2m(@yosou_umaban).join("\n")
		
		@blog_ogp = get_text_OGP(@shutubahyo, @yosou_umaban).join("\n")
		
		@name_honmei = get_name_honmei(@yosou_umaban, @shutubahyo)
	end
	
	#馬番と馬名を返す
	def get_text_umamei(umaban, shutubahyo)
		text = Array.new
		
		name_uma = shutubahyo[umaban - 1].uma_name
		
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
		rate_rank_s = get_rate_taisen_rank(taisen_rank.count_rank_s, taisen_rank.count_rank_all)
		rate_rank_a = get_rate_taisen_rank(taisen_rank.count_rank_a, taisen_rank.count_rank_all)
		rate_rank_b = get_rate_taisen_rank(taisen_rank.count_rank_b, taisen_rank.count_rank_all)
		rate_rank_c = get_rate_taisen_rank(taisen_rank.count_rank_c, taisen_rank.count_rank_all)
		rate_rank_d = get_rate_taisen_rank(taisen_rank.count_rank_d, taisen_rank.count_rank_all)
		
		text << "▽対戦型予測の分布："
		text << "Sランク：" + taisen_rank.count_rank_s.to_s + "頭　" + rate_rank_s
		text << "Aランク：" + taisen_rank.count_rank_a.to_s + "頭　" + rate_rank_a
		text << "Bランク：" + taisen_rank.count_rank_b.to_s + "頭　" + rate_rank_b
		text << "Cランク：" + taisen_rank.count_rank_c.to_s + "頭　" + rate_rank_c
		text << "Dランク：" + taisen_rank.count_rank_d.to_s + "頭　" + rate_rank_d
		
		return text
	end
	
	#買い目
	#三連単２頭軸マルチの生成用
	#これ、汎用的にできたりしないかな？　ひょっとしたら、予想と一緒に生成した方がいいかも
	def get_text_kaime_sanrentan_2m(yosou_umaban)
		jiku_a = format("%02d", yosou_umaban.jiku_a)
		jiku_b = format("%02d", yosou_umaban.jiku_b)
		
		aite = Array.new
		
		yosou_umaban.himo.each do |umaban|
			aite << format("%02d", umaban)
		end
		
		text = Array.new
		text << "▽買い目"
		text << "三連単２頭軸流し（マルチ）"
		text << jiku_a.to_s + " - " + jiku_b.to_s + " - " + aite.join(", ")
		text << ""	#改行用
		
		#本命が１着のもの
		text << "買い目A"
		aite.each do |umaban|
			text << jiku_a + " - " + jiku_b + " - " + umaban
		end
		aite.each do |umaban|
			text << jiku_a + " - " + umaban + " - " + jiku_b
		end
		text << ""	#改行用
		
		text << "買い目B"
		aite.each do |umaban|
			text << jiku_b + " - " + jiku_a + " - " + umaban
		end
		aite.each do |umaban|
			text << jiku_b + " - " + umaban + " - " + jiku_a
		end
		text << ""	#改行用
		
		text << "買い目C　※削っても可"
		aite.each do |umaban|
			text << umaban + " - " + jiku_a + " - " + jiku_b
			text << umaban + " - " + jiku_b + " - " + jiku_a
		end
		text << ""	#改行用
		text << ""	#改行用
		
		return text
	end
	
	#短評を作る部分
	#ぜんぜんスマートじゃないのをどうにかしたい
	#あと、ぜんぜん適当な内容なのもなんとかしたい
	def get_text_tanpyo(taisen_rank)
		rank_s = taisen_rank.count_rank_s
		rank_a = taisen_rank.count_rank_a
		rank_b = taisen_rank.count_rank_b
		rank_c = taisen_rank.count_rank_c
		rank_d = taisen_rank.count_rank_d
		
		race_evaluation = Hash.new
		race_evaluation.store("konsen",				0)
		race_evaluation.store("konsen_jiku",		1)
		race_evaluation.store("joui_konsen_5over",	2)
		race_evaluation.store("joui_konsen",		3)
		race_evaluation.store("kenjiku_aite1",		4)
		race_evaluation.store("kenjiku_aite_multi",	5)
		race_evaluation.store("rikiryokikkou",		6)
		race_evaluation.store("rikiryokikkou_no_s",	7)
		race_evaluation.store("ikkiuchi",			8)
		
		result = race_evaluation["konsen"]	#デフォルト値として混戦を入れておく
		
		#ここでは評価をするだけ。本文の生成は別途
		case rank_s
			when 2..18 then
			if rank_s + rank_a + rank_b >= 5 then
				#上位混戦_５頭越え
				result = race_evaluation["joui_konsen_5over"]
				else
				#上位混戦
				result = race_evaluation["joui_konsen"]
			end
			when 2 then
			if rank_a == 0 then
				#一騎打ち
				result = race_evaluation["ikkiuchi"]
			end
			when 1 then
			if rank_a == 1 then
				#頭堅い　相手１頭
				result = race_evaluation["kenjiku_aite1"]
				elsif rank_a > 1 then
				#頭堅い　相手複数
				result = race_evaluation["kenjiku_aite_multi"]
				elsif rank_a == 0 && rank_b == 1 then
				#頭堅い　相手１頭
				result = race_evaluation["kenjiku_aite1"]
				elsif rank_a == 0 && rank_b > 1 then
				#頭堅い　相手複数
				result = race_evaluation["kenjiku_aite_multi"]
				elsif rank_a == 0 && rank_b == 0 && rank_c == 1 then
				#頭堅い　相手１頭
				result = race_evaluation["kenjiku_aite1"]
				elsif rank_a == 0 && rank_b == 0 && rank_c > 1then
				#頭堅い　相手複数
				result = race_evaluation["kenjiku_aite_multi"]
			end
			when 0 then
			if rank_a >= 3 then
				#力量拮抗
				result = race_evaluation["rikiryokikkou"]
				elsif rank_a == 2 then
				#一騎打ち
				result = race_evaluation["ikkiuchi"]
				elsif rank_a == 1 && rank_b == 1 then
				#一騎打ち
				result = race_evaluation["ikkiuchi"]
				elsif rank_a == 1 && rank_b == 0 then
				#堅軸
				result = race_evaluation["kenjiku"]
				elsif rank_a + rank_b >= 3 then
				#力量拮抗　Sランクなし
				result = race_evaluation["rikiryokikkou_no_s"]
			end
		end
		#SランクもAランクもいない時
		if rank_s == 0 && rank_a == 0 then
			case rank_b
				when 2..18 then
				#混戦　軸なし
				result = race_evaluation["konsen"]
				else
				#混戦軸あり
				result = race_evaluation["konsen_jiku"]
			end
		end
		
		text = Array.new
		text << "▽短評"
		#短評の部分
		if result == race_evaluation["konsen"] then
			text << "混戦"
			text << "特に軸にできる馬もなく、何が勝つかわからないというレースです。"
			text << "一か八かの高配当を狙うのも面白いかもしれません。"
			elsif result == race_evaluation["konsen_jiku"] then
			text << "混戦"
			text << "特に軸にできる馬もなく、何が勝つかわからないというレースです。"
			text << "一か八かの高配当を狙うのも面白いかもしれません。"
			elsif result == race_evaluation["joui_konsen_5over"] then
			text << "上位混戦"
			text << "勝てる可能性の高い馬が多く、上位が混戦となっているレースです。"
			elsif result == race_evaluation["joui_konsen"] then
			text << "上位混戦"
			text << "勝てる可能性の高い馬が多く、上位が混戦となっているレースです。"
			text << "しかし、相手とする馬は絞れそうです。"
			elsif result == race_evaluation["kenjiku_aite1"] then
			text << "不動の軸"
			text << "本命として抜けた馬が１頭＋対抗としても良さそうな抜けた馬が１頭います。"
			elsif result == race_evaluation["kenjiku_aite_multi"] then
			text << "不動の軸"
			text << "マイニングのスコアで抜けた馬が１頭います。"
			elsif result == race_evaluation["rikiryokikkou"] then
			text << "力量拮抗"
			text << "対戦型マイニング予測的に優秀なスコアの馬が多く、混戦と言えそうです。"
			text << "実力的にはわりと差がありませんが、レースによっては１着になれるような馬が複数頭います。"
			elsif result == race_evaluation["rikiryokikkou_no_s"] then
			text << "力量拮抗"
			text << "Ｓランクも含め、上位の馬が拮抗していると考えられるレースです。"
			text << "対戦型マイニング予測的に優秀なスコアの馬が多く、ハイレベルな一戦になりそうです。"
			elsif result == race_evaluation["ikkiuchi"] then
			text << "一騎打ち"
			text << "抜けた馬が２頭います。"
		end
		
		text << ""	#改行用
		
		return text
	end
	
	#本命とか表示する部分
	def get_text_list_umamei(yosou_umaban, shutubahyo)
		text = Array.new
		
		#馬名とかの取得をして入れていく
		text << "▽軸馬1"
		text << get_text_umamei(yosou_umaban.jiku_a, shutubahyo)
		text << ""	#改行用
		
		text << "▽軸馬2"
		text << get_text_umamei(yosou_umaban.jiku_b, shutubahyo)
		text << ""	#改行用
		
		text << "▽相手"
		yosou_umaban.himo.each do |umaban|
			text << get_text_umamei(umaban, shutubahyo)
		end
		text << ""	#改行用
		text << ""	#改行用
		
		return text
	end
	
	#本命馬の名前取る
	def get_name_honmei(yosou_umaban, shutubahyo)
		name_honmei = shutubahyo[yosou_umaban.jiku_a - 1].uma_name
		return name_honmei
	end
	
	def get_name_race(shutubahyo)
		temp_uma = shutubahyo[0]	#適当な馬を抜き出す
		name_race = temp_uma.uma_basho + format("%02d",temp_uma.uma_race_num) + "R"	#中山1Rとかそんな形
		
		return name_race
	end
	
	#記事概要を作る
	#実際に使うのはメインレースのものだけだけど
	def get_text_OGP(shutubahyo, yosou_umaban)
		text = Array.new
		
		jiku_a	= yosou_umaban.jiku_a
		jiku_b	= yosou_umaban.jiku_b
		himo	= yosou_umaban.himo
		
		name_race = get_name_race(shutubahyo)
		
		#馬名とかの取得をして入れていく
		umamei_honmei = get_text_umamei(yosou_umaban.jiku_a, shutubahyo).join
		umamei_taikou = get_text_umamei(yosou_umaban.jiku_b, shutubahyo).join
		umamei_aite = Array.new
		yosou_umaban.himo.each do |umaban|
			umamei_aite << get_text_umamei(umaban, shutubahyo)
		end
		
		text << name_race + "。本命は、" + umamei_honmei + "。"
		text << "対抗、" + umamei_taikou + "な買い目を公開中。"
		text << "障害戦を除く、対戦型マイニング予測が提供されている全レースで、予想の公開しています。"
		text << "2013年〜2015年のシミュレーション結果は回収率100%超を達成。2016年も続けるか！？"
		
		return text
	end
	
	def test
		#puts get_text_bunpu_taisen_rank(@taisen_rank)
		#puts get_text_tanpyo(@taisen_rank)
		#puts get_text_list_umamei(@yosou_umaban, @shutubahyo)
		#puts get_text_kaime_sanrentan_2m(@yosou_umaban)
		#puts get_text_OGP(@shutubahyo, @yosou_umaban)
		puts @blog_text, "*"*30, @blog_ogp
	end
end


#通常予想のテキストを得る処理
def get_blog_text(kaisai)
	#場所ごとにテキストを保存するためのハッシュを用意する
	#場所idごとにText_basho（１つの記事にするためのかたまり）を作る。
	blog_text = Hash.new
	kaisai.list_basho.each do |basho_id|
		blog_text[basho_id] = Text_basho.new
	end
	
	#開催に含まれるレースID分だけ繰り返す
	list_raceid = kaisai.list_raceid
	list_raceid.each do |raceid|
		shutubahyo = kaisai.get_shutubahyo(raceid)
		
		yosou = Yosou.new(shutubahyo)
		
		#予想がエラーじゃなければ、テキストに加える
		#エラーだった場合はスキップしちゃう
		if yosou.error == false then
			text_race = Text_race.new(shutubahyo, yosou)
			
			#レースIDの前12桁が場所idにあたる
			#場所idのオブジェクト？ごとにテキストを振り分ける
			basho_id = raceid[0..11]
			blog_text[basho_id].add_text_race(text_race)
			
			#メインレースなら概要を足す
			#ついでにブログタイトルも
			flag_main = shutubahyo.flag_main
			if flag_main == true then
				blog_text[basho_id].add_text_ogp(text_race)
				blog_text[basho_id].add_text_title(shutubahyo)
				blog_text[basho_id].add_text_honmei(text_race)	#本命も足す
			end
		end
	end
	
	return blog_text
end
