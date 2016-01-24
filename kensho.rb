#! ruby -Ku

=begin
 2016/01/24
 買い目の検証用
=end

require "fileutils"
require "CSV"
require "json"

require "./config.rb"

require "./read_csv.rb"
require "./yosou.rb"

require "./generate_haitou.rb"


############################################################


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
kensho_kaime.compact!.reject(&:empty?)

#テスト
#puts kensho_kaime
puts get_haitou_data()
