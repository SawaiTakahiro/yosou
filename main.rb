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

############################################################
#読み込ませるファイル（仮）
PATH_SOURCE_SHUTUBAHYO = "./source/sample_shutubahyo_20160108.csv"
data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)

#読み込んだデータを、扱いやすい形に変換
kaisai = Kaisai.new(data_csv)

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
	end
	
end


#テスト用。開催ID
#RX2016010906
#RX2016010908
puts blog_text["RX2016010906"].list_text_race
