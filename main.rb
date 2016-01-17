#! ruby -Ku

=begin
 2016/01/14
 ブログに投稿する用のテキストを生成するスクリプト
 
=end

require "fileutils"
require "CSV"
require "json"

require "readline"	#コピペ用

require "./config.rb"

require "./read_csv.rb"
require "./yosou.rb"
require "./blog_text.rb"
require "./pickup_uma.rb"

#入力支援
#テキストを、ブログへ貼り付ける単位で、クリップボードに書き込む
def copy_paste_support(text)
	#クリップボードに足す
	system "echo \"#{text}\" | pbcopy"
	
	print "キーを押すと進む\n"
	Readline.readline	#入力待ちする。適当なキーを押すと進む
end


############################################################
data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)

#読み込んだデータを、扱いやすい形に変換
kaisai = Kaisai.new(data_csv)

#=begin
#通常予想のテキスト Text_basho形式
#コースごとに繰り返す
blog_text = get_blog_text(kaisai)
blog_text.each do |key, value|
	p "記事のタイトル"
	copy_paste_support(value.text_title)
	
	p "ブログの本文"
	copy_paste_support(value.list_text_race.join)
	
	p "タグ"
	copy_paste_support(value.name_honmei)
	
	p "記事の概要"
	copy_paste_support(value.text_ogp)
	
	p "トラックバックの送信先"
	copy_paste_support(TRACKBACKLIST)
end
#=end

#厳選馬のテキストを作る
gensen_uma = Gensen_uma.new(data_csv)
blog_gensen_uma = gensen_uma.blog_gensen_uma

p "記事のタイトル"
copy_paste_support(gensen_uma.text_title)

p "ブログの本文"
copy_paste_support(blog_gensen_uma.join)

p "トラックバックの送信先"
copy_paste_support(TRACKBACKLIST)
