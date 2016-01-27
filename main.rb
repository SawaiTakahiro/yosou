#! ruby -Ku

=begin
 2016/01/14
 ブログに投稿する用のテキストを生成するスクリプト
 
=end

require "fileutils"
require "CSV"
require "json"

#require "readline"	#コピペ用

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

kaisai.list_basho

#=begin
#通常予想のテキスト Text_basho形式
#コースごとに繰り返す
blog_text = get_blog_text(kaisai)
kaisai.list_basho.each do |key|
	text_zenhan = blog_text[key + "01"]
	text_kouhan = blog_text[key + "02"]
	
	#テキスト、タグ、記事の概要は後半の方に入っている
	p key
	p "記事のタイトル"
	copy_paste_support(text_kouhan.text_title)
	
	p "ブログの本文（前半）"
	copy_paste_support(text_zenhan.list_text_race.join)
	
	p "ブログの本文（後半）"
	copy_paste_support(text_kouhan.list_text_race.join)
	
	p "タグ"
	copy_paste_support(text_kouhan.name_honmei)
	
	p "記事の概要"
	copy_paste_support(text_kouhan.text_ogp)
	
	p "トラックバックの送信先"
	copy_paste_support(TRACKBACKLIST)
end
#=end


kensho_kaime = Array.new

#検証用の買い目IDを取り出す
list_raceid = kaisai.list_raceid
list_raceid.each do |raceid|
	shutubahyo = kaisai.get_shutubahyo(raceid)
	
	yosou = Yosou.new(shutubahyo)
	kensho_kaime << yosou.list_kaimeid
end

#これで空白行を削除する
kensho_kaime.flatten!.compact!.reject(&:empty?)

############################################################
#puts kensho_kaime

#保存フォルダの用意
path = "output/kaime/"
FileUtils.mkdir_p(path) unless FileTest.exist?(path)

save_file = "kaime" + (kensho_kaime[0][2..9]) + ".txt"
File.open(path + save_file, "w"){|file| file.write kensho_kaime.join("\n")}


#=begin
#厳選馬のテキストを作る
gensen_uma = Gensen_uma.new(data_csv)
blog_gensen_uma = gensen_uma.blog_gensen_uma

p "厳選馬の記事"
p "記事のタイトル"
copy_paste_support(gensen_uma.text_title)

p "ブログの本文"
copy_paste_support(blog_gensen_uma.join)

p "トラックバックの送信先"
copy_paste_support(TRACKBACKLIST)
#=end

