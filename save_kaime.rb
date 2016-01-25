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

#↑ここまでは、買い目検証と同じ
#あとでどうにかしてまとめる
############################################################
#puts kensho_kaime

#保存フォルダの用意
path = "output/kaime/"
FileUtils.mkdir_p(path) unless FileTest.exist?(path)

save_file = "kaime" + (kensho_kaime[0][2..9]) + ".txt"
File.open(path + save_file, "w"){|file| file.write kensho_kaime.join("\n")}
