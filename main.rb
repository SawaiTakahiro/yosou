#! ruby -Ku

=begin
 2016/01/14
 ブログに投稿する用のテキストを生成するスクリプト
 
=end

require "fileutils"
require "CSV"
require "json"

require "./read_csv.rb"
require "./yosou.rb"
require "./blog_text.rb"
require "./pickup_uma.rb"

############################################################
#読み込ませるファイル（仮）
PATH_SOURCE_SHUTUBAHYO = "./source/sample_shutubahyo_20160108.csv"
data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)

#読み込んだデータを、扱いやすい形に変換
kaisai = Kaisai.new(data_csv)

#通常予想のテキスト
blog_text = get_blog_text(kaisai)

#テスト用。開催ID
#RX2016010906
#RX2016010908
#puts blog_text["RX2016010906"].list_text_race

#厳選馬のテキストを作る
gensen_uma = Gensen_uma.new(data_csv)
text = to_text_gensen_uma(gensen_uma.pickup_list_score)	#対戦型スコア準拠
puts text
text = to_text_gensen_uma(gensen_uma.pickup_list_okaidoku)	#オッズが狙い目な馬
puts text


