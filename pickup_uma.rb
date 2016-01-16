#! ruby -Ku

=begin
 2016/01/16
 厳選馬をピックアップするスクリプト
 出馬表じゃなく、開催単位でデータを探していくはずなので予想とは別ロジックになるはず。
=end

require "fileutils"
require "CSV"
require "json"

require "./read_csv.rb"

############################################################
#読み込ませるファイル（仮）
PATH_SOURCE_SHUTUBAHYO = "./source/sample_shutubahyo_20160108.csv"
data_csv = read_csv(PATH_SOURCE_SHUTUBAHYO)
