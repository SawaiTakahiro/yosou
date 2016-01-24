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

#補足　払い戻しコードについて
#RX20160117080106060169999
#RXyyyymmdd回次とかXXaabbcc
#XXは馬券ID、馬番が0詰め２桁で３頭分。
#単勝とかは無い馬番を99で埋めている

############################################################


############################################################
data_csv = read_csv("./source/201601_shutubahyo.csv")

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

#払い戻しの一覧
#払い戻しコード, 配当というハッシュ
HARAIMODOSHI = get_haitou_data()

#テスト
system "echo \"#{kensho_kaime}\" > hoge.txt"

sum_haraimodoshi = 0
kensho_kaime.each do |key|
	temp = HARAIMODOSHI[key]
	
	if temp != nil then
		sum_haraimodoshi += temp
		print key, "	:	", temp, "\n"
	end
end

p "*"*20
print "購入金額合計	", kensho_kaime.length * 100, "\n"
print "払い戻し合計	", sum_haraimodoshi, "\n"
