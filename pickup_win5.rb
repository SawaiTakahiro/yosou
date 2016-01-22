#! ruby -Ku

=begin
 2016/01/22
 
 厳選馬。win5用のオプション予想。
=end

require "fileutils"
require "CSV"
require "json"

require "./config.rb"

require "./read_csv.rb"

require "date"

#YYYYMMDDという形の数字を日付に変換
#それが土曜日か返すメソッド
#土曜日=win5が無い日なので。その他の曜日で開催している=WIN5があるはず
def check_saturday(text_date)
	
	#渡されたテキストをdateに変換
	date = Date.strptime(text_date, "%Y%m%d")
	
	#wdayが6だったら土曜日
	if date.wday == 6 then
		return true
	else
		return false
	end
end

text = "20160123"	#テスト用
flag_saturday = check_saturday(text)

#土曜日でない = WIN5がある日なら
if flag_saturday != true then
	p 
end