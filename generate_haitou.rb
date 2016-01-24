#! ruby -Ku

=begin
 2016/01/24
 Targetから出力した成績ファイルをあれこれするためのスクリプト
 
 前に作っていたスクリプトの移植。
 配当CSVを解析して、配当データを抜き出す。
=end

require "fileutils"
require "CSV"
require "json"

#配当CSVからレースIDを取得して返す
def get_raceid_no_num(record)
	temp = Array.new
	temp << "RX20"	#レースIDはRXから始まる＋年が下二桁で入っているので４桁に直すため
	temp << record[INDEX_SORCE["year"]]
	temp << record[INDEX_SORCE["month"]]
	temp << record[INDEX_SORCE["day"]]
	temp << (record[INDEX_SORCE["old_raceid"]])[2..3]	#旧レースIDから場所コードを抜き出す
	temp << format("%02d", record[INDEX_SORCE["kaiji"]])	#0埋めする
	temp << format("%02d", record[INDEX_SORCE["nichiji"]])	#0埋めする
	temp << record[INDEX_SORCE["race_num"]]
	
	return temp.join
end

#87	単勝馬番1,
#88	単勝配当1,
#89	単勝馬番2,
#90	単勝配当2,
#91	単勝馬番3,
#92	単勝配当3,
#93	複勝馬番1,
#94	複勝配当1,
#95	複勝馬番2,
#96	複勝配当2,
#97	複勝馬番3,
#98	複勝配当3,
#99	複勝馬番4,
#100	複勝配当4,
#101	複勝馬番5,
#102	複勝配当5,

#単勝
def get_haitou_tansho(record)
	output = Array.new
	
	index = INDEX_SORCE["tansho_start"]
	
	#単勝は最大で３個まで => 3-1で2まで
	for i in 0..2 do
		offset = i * 2	#項目は2つで構成されているので
		
		#１着馬が0の時 = 配当が存在しない
		#その時点で抜ける
		if record[index + 0 + offset].to_i == 0 then
			break
		end
		
		
		temp = Array.new
		temp << record[index + 0 + offset].to_i	#馬１
		temp << 99								#ダミー
		temp << 99								#ダミー
		temp << record[index + 1 + offset].to_i	#払い戻し
		temp << 0	#単勝は人気が並んでないのでダミーの0を入れておく
		#temp << record[index + 2 + offset].to_i	#馬連の人気
		
		output << temp
	end
	
	return output
end

#馬連も追加
def get_haitou_umaren(record)
	output = Array.new
	
	index = INDEX_SORCE["umaren_start"]
	
	#馬連は最大で３個まで => 3-1で2まで
	for i in 0..2 do
		offset = i * 4	#項目は４つで構成されているので
		
		#１着馬が0の時 = 配当が存在しない
		#その時点で抜ける
		if record[index + 0 + offset].to_i == 0 then
			break
		end
		
		
		temp = Array.new
		temp << record[index + 0 + offset].to_i	#馬１
		temp << record[index + 1 + offset].to_i	#馬２
		temp << 99								#ダミー
		temp << record[index + 2 + offset].to_i	#払い戻し
		temp << record[index + 3 + offset].to_i	#馬連の人気
		
		output << temp
	end
	
	return output
end

#三連単部分をパースする
def get_haitou_sanrentan(record)
	output = Array.new
	
	index = INDEX_SORCE["sanrentan_start"]
	
	#最大で６個分配当がある
	for i in 0..5 do
		offset = i * 5
		
		#１着馬が0の時 = 配当が存在しない
		#その時点で抜ける
		if record[index + 0 + offset].to_i == 0 then
			break
		end
		
		
		temp = Array.new
		temp << record[index + 0 + offset].to_i	#１着馬
		temp << record[index + 1 + offset].to_i	#２着馬
		temp << record[index + 2 + offset].to_i	#３着馬
		temp << record[index + 3 + offset].to_i	#払い戻し
		temp << record[index + 4 + offset].to_i	#三連単の人気。使うかわからないけど
		
		output << temp
	end
	
	return output
end

#配当だけをまとめた形式で返す
=begin
 引数は、配当をパースしたものと同じ。
 払い戻し１件ずつ処理する。単勝なら単勝１件のみ、複勝なら複勝１件のみ渡すこと。
 １着馬の番号、２着馬の番号、３着馬の番号、払い戻し金額、（その買い目の人気）
 人気は使わないから無くても平気かも
=end
def get_list_seiseki(raceid_no_num, haitou, category)
	#馬番を0埋めして持っておく
	umaban_1st = format("%02d",haitou[0])
	umaban_2nd = format("%02d",haitou[1])
	umaban_3rd = format("%02d",haitou[2])
	
	temp = Hash.new
	temp.store("id", raceid_no_num + category.to_s + umaban_1st + umaban_2nd + umaban_3rd)
	temp.store("price", haitou[3])

	return temp
end

#######################################################
#以下、処理の部分
#馬券の種類。targetの買い目データ準拠
BAKEN_ID = Hash.new
BAKEN_ID.store("tansho",	0)
BAKEN_ID.store("fukusho",	1)
BAKEN_ID.store("wakuren",	2)
BAKEN_ID.store("umaren",	3)
BAKEN_ID.store("wide",		4)
BAKEN_ID.store("umatan",	5)
BAKEN_ID.store("sanrenfuku",6)
BAKEN_ID.store("sanrentan",	7)

BAKEN_BUY = Hash.new
BAKEN_BUY.store("normal",	0)
BAKEN_BUY.store("nagashi",	1)
BAKEN_BUY.store("box",		2)
BAKEN_BUY.store("multi",	3)

BAKEN_RANGE = Hash.new
BAKEN_RANGE.store("narrow",	0)
BAKEN_RANGE.store("normal",	1)
BAKEN_RANGE.store("wide",	2)


#targetで出力したものはshift_jisだから、utfにしておく
def read_csv(file_path_csv)
	data_csv = CSV.read(file_path_csv, encoding: "Shift_JIS:UTF-8")
	
	return data_csv
end

#配当CSVの形式
#http://faqnavi13a.csview.jp/faq2/userqa.do?user=jravan&faq=faq01_target&id=286&parent=20
#三連単が欲しかったりするので、タイプAのものを使っている

#サンプル
PATH_CSV_SORCE = "./source/201601_haraimodoshi.csv"
TABLE_SORCE = read_csv(PATH_CSV_SORCE)	#これ自体は書き換えないので定数

=begin
 CSVを読み取る用
 全部で200項目ぐらいあったりするし…
 全部は要らないので、必要なものだけ項目に。
=end
=begin
 全項目
 0	年,
 1	月,
 2	日,
 3	回次,
 4	場所,
 5	日次,
 6	レース番号,
 7	レース名,
 8	クラスコード,
 9	芝・ダ,
 10	コースコード,
 11	距離,
 12	馬場状態,
 13	頭数,
 14	レースID,
 15	1番馬着順,
 16	1番馬異常コード,
 17	1番馬人気,
 18	1番馬単勝オッズ,
 19	2番馬着順,
 20	2番馬異常コード,
 21	2番馬人気,
 22	2番馬単勝オッズ,
 23	3番馬着順,
 24	3番馬異常コード,
 25	3番馬人気,
 26	3番馬単勝オッズ,
 27	4番馬着順,
 28	4番馬異常コード,
 29	4番馬人気,
 30	4番馬単勝オッズ,
 31	5番馬着順,
 32	5番馬異常コード,
 33	5番馬人気,
 34	5番馬単勝オッズ,
 35	6番馬着順,
 36	6番馬異常コード,
 37	6番馬人気,
 38	6番馬単勝オッズ,
 39	7番馬着順,
 40	7番馬異常コード,
 41	7番馬人気,
 42	7番馬単勝オッズ,
 43	8番馬着順,
 44	8番馬異常コード,
 45	8番馬人気,
 46	8番馬単勝オッズ,
 47	9番馬着順,
 48	9番馬異常コード,
 49	9番馬人気,
 50	9番馬単勝オッズ,
 51	10番馬着順,
 52	10番馬異常コード,
 53	10番馬人気,
 54	10番馬単勝オッズ,
 55	11番馬着順,
 56	11番馬異常コード,
 57	11番馬人気,
 58	11番馬単勝オッズ,
 59	12番馬着順,
 60	12番馬異常コード,
 61	12番馬人気,
 62	12番馬単勝オッズ,
 63	13番馬着順,
 64	13番馬異常コード,
 65	13番馬人気,
 66	13番馬単勝オッズ,
 67	14番馬着順,
 68	14番馬異常コード,
 69	14番馬人気,
 70	14番馬単勝オッズ,
 71	15番馬着順,
 72	15番馬異常コード,
 73	15番馬人気,
 74	15番馬単勝オッズ,
 75	16番馬着順,
 76	16番馬異常コード,
 77	16番馬人気,
 78	16番馬単勝オッズ,
 79	17番馬着順,
 80	17番馬異常コード,
 81	17番馬人気,
 82	17番馬単勝オッズ,
 83	18番馬着順,
 84	18番馬異常コード,
 85	18番馬人気,
 86	18番馬単勝オッズ,
 87	単勝馬番1,
 88	単勝配当1,
 89	単勝馬番2,
 90	単勝配当2,
 91	単勝馬番3,
 92	単勝配当3,
 93	複勝馬番1,
 94	複勝配当1,
 95	複勝馬番2,
 96	複勝配当2,
 97	複勝馬番3,
 98	複勝配当3,
 99	複勝馬番4,
 100	複勝配当4,
 101	複勝馬番5,
 102	複勝配当5,
 103	枠連目小1,
 104	枠連目大1,
 105	枠連配当1,
 106	枠連人気1,
 107	枠連目小2,
 108	枠連目大2,
 109	枠連配当2,
 110	枠連人気2,
 111	枠連目小3,
 112	枠連目大3,
 113	枠連配当3,
 114	枠連人気3,
 115	馬連目小1,
 116	馬連目大1,
 117	馬連配当1,
 118	馬連人気1,
 119	馬連目小2,
 120	馬連目大2,
 121	馬連配当2,
 122	馬連人気2,
 123	馬連目小3,
 124	馬連目大3,
 125	馬連配当3,
 126	馬連人気3,
 127	ワイド目小1,
 128	ワイド目大1,
 129	ワイド配当1,
 130	ワイド人気1,
 131	ワイド目小2,
 132	ワイド目大2,
 133	ワイド配当2,
 134	ワイド人気2,
 135	ワイド目小3,
 136	ワイド目大3,
 137	ワイド配当3,
 138	ワイド人気3,
 139	ワイド目小4,
 140	ワイド目大4,
 141	ワイド配当4,
 142	ワイド人気4,
 143	ワイド目小5,
 144	ワイド目大5,
 145	ワイド配当5,
 146	ワイド人気5,
 147	ワイド目小6,
 148	ワイド目大6,
 149	ワイド配当6,
 150	ワイド人気6,
 151	ワイド目小7,
 152	ワイド目大7,
 153	ワイド配当7,
 154	ワイド人気7,
 155	馬単目先1,
 156	馬単目後1,
 157	馬単配当1,
 158	馬単人気1,
 159	馬単目先2,
 160	馬単目後2,
 161	馬単配当2,
 162	馬単人気2,
 163	馬単目先3,
 164	馬単目後3,
 165	馬単配当3,
 166	馬単人気3,
 167	馬単目先4,
 168	馬単目後4,
 169	馬単配当4,
 170	馬単人気4,
 171	馬単目先5,
 172	馬単目後5,
 173	馬単配当5,
 174	馬単人気5,
 175	馬単目先6,
 176	馬単目後6,
 177	馬単配当6,
 178	馬単人気6,
 179	３連複目小1,
 180	３連複目中1,
 181	３連複目大1,
 182	３連複配当1,
 183	３連複人気1,
 184	３連複目小2,
 185	３連複目中2,
 186	３連複目大2,
 187	３連複配当2,
 188	３連複人気2,
 189	３連複目小3,
 190	３連複目中3,
 191	３連複目大3,
 192	３連複配当3,
 193	３連複人気3,
 194	３連単目1着1,
 195	３連単目2着1,
 196	３連単目3着1,
 197	３連単配当1,
 198	３連単人気1,
 199	３連単目1着2,
 200	３連単目2着2,
 201	３連単目3着2,
 202	３連単配当2,
 203	３連単人気2,
 204	３連単目1着3,
 205	３連単目2着3,
 206	３連単目3着3,
 207	３連単配当3,
 208	３連単人気3,
 209	３連単目1着4,
 210	３連単目2着4,
 211	３連単目3着4,
 212	３連単配当4,
 213	３連単人気4,
 214	３連単目1着5,
 215	３連単目2着5,
 216	３連単目3着5,
 217	３連単配当5,
 218	３連単人気5,
 219	３連単目1着6,
 220	３連単目2着6,
 221	３連単目3着6,
 222	３連単配当6,
 223	３連単人気6
=end
INDEX_SORCE = Hash.new
INDEX_SORCE.store("year",		0)
INDEX_SORCE.store("month",		1)
INDEX_SORCE.store("day",		2)
INDEX_SORCE.store("kaiji",		3)
INDEX_SORCE.store("nichiji",	5)
INDEX_SORCE.store("race_num",	6)
INDEX_SORCE.store("old_raceid",	14)
INDEX_SORCE.store("sanrentan_start",	194)
INDEX_SORCE.store("umaren_start",		115)
INDEX_SORCE.store("tansho_start",		87)


#成績ファイルから配当を生成する一連の処理
#産連単、馬連、単勝しか生成してない。必要ならその他も足すこと
def get_haitou_data()
	seiseki = Hash.new
	TABLE_SORCE.each do |record|
		#レースごとに、レースidと三連単の配当を求める。
		#それを出力用のハッシュに、id, 配当の形で追加する => 別のスクリプトで、idをキーに検索できるように
		
		raceid_no_num = get_raceid_no_num(record)
		
		########################################################################
		#三連単の処理
		haitou_sanrentan = get_haitou_sanrentan(record)
		
		#１件ずつ、配当のデータを渡して処理
		haitou_sanrentan.each do |data|
			temp = get_list_seiseki(raceid_no_num, data, BAKEN_ID["sanrentan"])
			seiseki.store(temp["id"], temp["price"])
		end
		
		########################################################################
		#馬連の処理
		haitou_umaren = get_haitou_umaren(record)
		
		#１件ずつ、配当のデータを渡して処理
		haitou_umaren.each do |data|
			temp = get_list_seiseki(raceid_no_num, data, BAKEN_ID["umaren"])
			seiseki.store(temp["id"], temp["price"])
		end
		
		########################################################################
		#単勝の処理
		haitou_tansho = get_haitou_tansho(record)
		
		#１件ずつ、配当のデータを渡して処理
		haitou_tansho.each do |data|
			temp = get_list_seiseki(raceid_no_num, data, BAKEN_ID["tansho"])
			seiseki.store(temp["id"], temp["price"])
		end
		
		#三連単以外処理したい場合は、配当をパースするメソッドを作って同じようにやればいいはず
	end
	#save_json(PATH_JSON_HARAIMODOSHI, seiseki)	#保存しておく
	
	return seiseki
end