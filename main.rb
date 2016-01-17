#! ruby -Ku

=begin
 2016/01/14
 ブログに投稿する用のテキストを生成するスクリプト
 
=end

require "fileutils"
require "CSV"
require "json"

require "./config.rb"

require "./read_csv.rb"
require "./yosou.rb"
require "./blog_text.rb"
require "./pickup_uma.rb"

############################################################
data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)

#読み込んだデータを、扱いやすい形に変換
kaisai = Kaisai.new(data_csv)

#通常予想のテキスト
#Text_basho形式
blog_text = get_blog_text(kaisai)
blog_text.each do |key, value|
	p "*" * 30
	puts value.text_title
	puts value.list_text_race
	puts value.text_ogp
end

#テスト用。開催ID
#RX2016010906
#RX2016010908
#puts blog_text["RX2016010906"].list_text_race

#厳選馬のテキストを作る
gensen_uma = Gensen_uma.new(data_csv)
text = to_text_gensen_uma(gensen_uma.pickup_list_score)	#対戦型スコア準拠
text = to_text_gensen_uma(gensen_uma.pickup_list_okaidoku)	#オッズが狙い目な馬

