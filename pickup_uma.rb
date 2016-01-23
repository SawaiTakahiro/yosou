#! ruby -Ku

=begin
 2016/01/16
 厳選馬をピックアップするスクリプト
 出馬表じゃなく、開催単位でデータを探していくはずなので予想とは別ロジックになるはず。
 
 ブログ用テキストを生成する部分もこれでしか使わなそうだったのでまとめた。
=end

require "fileutils"
require "CSV"
require "json"
require "date"

require "./config.rb"

require "./read_csv.rb"

#厳選馬。それ自体をクラスに
#いろいんな条件で抽出したshussoumaクラスの配列を持っている
#配列の種類はいろいろ増やしてみる
class Gensen_uma
	attr_reader :pickup_list_score, :pickup_list_okaidoku, :text_title, :blog_gensen_uma, :pickup_list_win5
	
	def initialize(data_csv)
		@text_title 			= get_date(data_csv)
		
		#それぞれの条件でピックアップしていく
		@pickup_list_score		= pickup_score(data_csv)
		@pickup_list_okaidoku	= pickup_okaidoku(data_csv)
		@pickup_list_win5		= pickup_win5(data_csv)
		
		
		#ブログへの出力よう
		@blog_gensen_uma		= get_blog_gensen_uma(self)
	end
	
	#日付の取得をする
	#ブログの記事に使うだけなので、日付自体は文字列。
	def get_date(data_csv)
		#作業用に適当なデータで出走馬を作る
		temp_shussouma	= Data_shussouma.new(data_csv[0])
		raceid_no_num	= temp_shussouma.uma_raceid_no_num
		
		year	= raceid_no_num[2..5]
		month	= raceid_no_num[6..7]
		day		= raceid_no_num[8..9]
		
		#「2016/01/11京都の対戦型データマイニング予測ピックアップ」とかって形
		return year + "/" + month + "/" + day + "の厳選馬"
	end
	
	#仮想複勝オッズを求めるメソッド
	#仮想の単勝オッズ / 2して、それの平方根を求めるとそれっぽい気がする？
	#１レコード分だけ処理して返す。必要になったらその都度呼ぶ感じ
	def get_virtual_odds_fukusho(odds)
		return Math.sqrt(odds / 2)
	end
	
	#出馬表データから、対戦型予測が50以上の馬だけ抜き出して返す
	#対戦型で50以下はまず用無しなので削っちゃう
	#やっぱり、どこで切るか？は引数でもてる方にした方がよさそう
	def ashikiri(data_csv, rate)
		pickup = data_csv.select do |record|
			race_num = record[9].to_i
			race_num >= rate
		end
		
		return pickup
	end
	
	#対戦型スコアが上位の馬だけを抜き出して返す
	def pickup_score(data_csv)
		#スコアが80以上のものだけピックアップ
		pickup = ashikiri(data_csv, 80)
		
		max = pickup.length
		#たくさんいた場合は上位5頭までにまとめる
		if max > 5 then
			max = 5
		end
		
		
		#対戦型のスコア順に並べる
		sort_pickup = pickup.sort{|a, b| b[9].to_i <=> a[9].to_i}
		
		temp = Array.new
		sort_pickup[0..max].each do |record|
			temp << Data_shussouma.new(record)
		end
		
		return sort_list_shussouma(temp)
	end
	
	#オッズがお買い得な馬をピックアップ
	def pickup_okaidoku(data_csv)
		#１回、開催データを作ってから加工し直す
		kaisai = Kaisai.new(data_csv)
		#puts kaisai.instance_variables
		
		list_shussouma = kaisai.get_list_shussouma	#その日に出る馬の一覧
		
		#条件に合う馬だけ抜き出して出力する
		temp = Array.new
		list_shussouma.each do |shussouma|
			#対戦予測が50未満なら飛ばす
			taisen_yosoku = shussouma.uma_taisen_yosoku
			next if taisen_yosoku < 50
			
			#複勝率はあるていど欲しい
			#参照先のキーが整数でしかも文字列だからごにょごにょしてる
			fukusho = DATA_MINING_INDEX[taisen_yosoku.to_i.to_s]["fukusho"]
			next if fukusho < 0.5
			
			#仮想複勝オッズを求めて判断。求め方は適当だけど…
			#仮想複勝オッズ自体は記事に盛り込まないので、ここだけで使う
			virtual_odds_fukusho = get_virtual_odds_fukusho(shussouma.uma_odds)
			next if virtual_odds_fukusho < 1.5
			
			#残ったものだけリストに追加
			temp << shussouma
		end
		
		return sort_list_shussouma(temp)
	end
	
	#出走馬が入ったリストを、レースID順に並べて返す
	#そのままだとソートができないので
	def sort_list_shussouma(list_shussouma)
		temp = Array.new
		list_shussouma.each do |shussouma|
			temp << [shussouma.uma_raceid, shussouma]
		end
		
		output = Array.new
		temp.sort.each do |raceid, shussouma|
			output << shussouma
		end
	
		return output
	end
	
	#厳選馬をブログの記事用にまとめたもの
	#配列形式でつなげたテキストにして返すので、必要に応じてjoinして使う
	def get_blog_gensen_uma(gensen_uma)
		blog_gensen_uma = Array.new
		
		blog_gensen_uma << "■対戦型予測スコアでの厳選馬<br>"
		blog_gensen_uma << to_text_gensen_uma(gensen_uma.pickup_list_score)	#対戦型スコア準拠
		blog_gensen_uma << "<br>"
		
		blog_gensen_uma << "■狙い目の馬<br>"
		blog_gensen_uma << to_text_gensen_uma(gensen_uma.pickup_list_okaidoku)	#オッズが狙い目な馬
		blog_gensen_uma << "<br>"
		
		#WIN5のある日なら
		if gensen_uma.pickup_list_win5.length != 0 then
			blog_gensen_uma << "■午後のレース<br>"
			blog_gensen_uma << to_text_gensen_uma(gensen_uma.pickup_list_win5)	#主にWIN5用
		end
		
		return blog_gensen_uma
	end
	
	#厳選馬を加工する
	#shussoumaが入った配列を使って、それを記事用のテキストにして返す
	#表みたいな形の方が見やすそうだったので、簡単なテーブル組に
	def to_text_gensen_uma(list_uma)
		#puts list_uma[0i].instance_variables
		
		text = Array.new
		list_uma.each do |shussouma|
			basho		= shussouma.uma_basho
			race_num	= shussouma.uma_race_num
			name		= shussouma.uma_text_umamei.join
			
			#勝率とかも入れる
			taisen_yosoku = shussouma.uma_taisen_yosoku
			seiseki		= DATA_MINING_INDEX[taisen_yosoku.to_i.to_s]
			shoritsu	= format("%d.0%", seiseki["shoritsu"] * 100)
			rentai		= format("%d.0%", seiseki["rentai"] * 100)
			fukusho		= format("%d.0%", seiseki["fukusho"] * 100)
			
			#print basho, race_num,"R ", name, " ",shoritsu," ",rentai," ",fukusho,"\n"
			#temp_text = basho + format("%02d", race_num) + "R " + name + " 勝率：" + shoritsu + " 複勝率：" + rentai + " 連対率：" + fukusho,"\n"
			temp_text = "<tr><td>" + basho + format("%02d", race_num) + "R</td><td>" + name + "</td><td>" + shoritsu + "</td><td>" + rentai + "</td><td>" + fukusho,"</td></tr>\n"
			
			text << temp_text
		end
		
		#とりあえず、出走馬の名前は200pxで固定に。文字数的には足りるはず
		header = '<table border="1"><tr><th>レース</th><th width="200px">名前</th><th>勝率</th><th>連対率</th><th>複勝率</th></tr>'
		footer = '</table>'
		return header + text.join + footer
	end
	
	
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
	
	#win5対象レースであろう馬からピックアップ
	def pickup_win5(data_csv)
		temp_shussouma	= Data_shussouma.new(data_csv[0])
		raceid_no_num	= temp_shussouma.uma_raceid_no_num
		
		#もしそれが土曜日のデータなら、空白を返す
		flag_saturday = check_saturday(raceid_no_num[2..9])
		return [] if flag_saturday == true
		
		#ダメそうな馬はこの時点で除外。まったく0になることはないはず
		pickup = ashikiri(data_csv, 50)
		
		#１回、開催データを作ってから加工し直す
		kaisai = Kaisai.new(pickup)
		
		#予想するレースを抜き出すところ
		#２場開催の時は９レースから予想する
		#違う時は、10レースから予想する
		if kaisai.list_basho.length == 2 then
			yosou_count = 4
			else
			yosou_count = 3
		end
		
		#実際に取得するところ
		list_yosou_race = Array.new
		kaisai.list_basho.each do |basho_id|
			#場所ごとにやるレース一覧を取得
			list_basho_betsu = kaisai.list_raceid.select{|raceid| raceid[0..11] == basho_id}
			
			#開催するレースの、後ろからyosou_count分取得
			temp_list = list_basho_betsu[yosou_count * -1, yosou_count]
			
			#それをリストに追加。
			#+=でやると配列をそのまま繋ぎこむみたい
			list_yosou_race += temp_list
		end
		
		temp = Array.new
		list_yosou_race.each do |raceid|
			list_shussouma = kaisai.get_shutubahyo(raceid).shutubahyo
			
			#条件に合う馬だけ抜き出して出力する
			list_shussouma.each do |shussouma|
				taisen_yosoku = shussouma.uma_taisen_yosoku
				
				#勝率せめて15%ほしい
				shoritsu = DATA_MINING_INDEX[taisen_yosoku.to_i.to_s]["shoritsu"]
				next if shoritsu < 0.15
				
				#残ったものだけリストに追加
				temp << shussouma
			end
			
		end
		
		return temp
	end
	
end
