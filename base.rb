#!/usr/bin/ruby

require 'rubygems'
require 'fusefs'
include FuseFS

require 'yaml'
require 'imlib2'
require 'LaughingEngine.rb'

#TODO
=begin
	秒数を工夫する。現状2秒でやっている。これはこのままでいいのか？
	やはり拡張子を工夫しないとおもしろくない。

	viやemacsなど主要なエディタで試してみる
=end
#=====================================================

class LaughingFS < FuseFS::FuseDir

	def initialize(filename)

		@last_contents_called = Time.now.to_i
		@nautilus_read = true
		@filename = filename

		# @fsにファイルの実体が格納される
		begin
			@fs = YAML.load(IO.read(filename))
		rescue Exception
			@fs = Hash.new()
		end
	end

	# YAML形式で@fsの状態を保存するメソッド
	# このメソッドはこのスクリプト内からしか呼ばれない
	def save
		File.open(@filename, 'w') do |fout|
			# 'w'で開いたら毎回内容がクリアされるような気がするが、大丈夫か？
			fout.puts(YAML.dump(@fs))
		end
	end

	def contents(path)
		printf("contents:%s\n", path)
		@last_contents_called = Time.now.to_i

		items = scan_path(path)
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end
		node.keys.sort
	end

	def directory?(path)
		items = scan_path(path)
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end
    	node.is_a?(Hash)
	end

	def file?(path)
		printf("file?:%s\n", path);
		items = scan_path(path)
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end
		node.is_a?(String)
	end

	def touch(path)
		puts "#{path} has been pushed like a button!"
	end

	#==================================
	# ファイルの読み込みを行うメソッド
	#==================================
	def read_file(path)
		#printf("read_file:%s\n")
		items = scan_path(path)
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end

		if(@nautilus_read)
		then	#nautilus経由
			#printf("read_file.to_s\n");
			node.to_s
		else	#エディタ経由
			#printf("read_file.decode\n");
			# LaughingEngineでデコードしたものを返す
			le = LaughingEngine.new
			le.read(node.to_s)
		end
	end
 
	def size(path)
		printf("size:%s\n", path)

		# 前回contentsが呼ばれた時よりも2秒以上経過していたら
		if(Time.now.to_i - @last_contents_called < 2)
		then
			@nautilus_read = true
		else
			@nautilus_read = false
			@last_contents_called = Time.now.to_i
		end

		read_file(path).size
	end

	#==================================
	# ファイルに書き込みを行うメソッド
	#==================================
	def can_write?(path)
		printf("can_write?:%s\n", path);
		items = scan_path(path)
		name = items.pop	#最後のものがファイル名になる
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end
		node.is_a?(Hash)
		rescue Exception => er
			puts "Error! #{er}"
	end

	def write_to(path, body)
		printf("write_to:%s\n", path)
		items = scan_path(path)	# itemsは配列
		name = items.pop # Last is the filename.

		# ここでディレクトリを再帰的に掘っている
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end

		le = LaughingEngine.new
		node[name] = le.write(body)

		self.save

		rescue Exception => er
			puts "Error! #{er}"
	end

	#==================================
	# ファイルを削除するメソッド
	#==================================
	def can_delete?(path)
		items = scan_path(path)
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end

		node.is_a?(String)
		rescue Exception => er
			puts "Error! #{er}"
	end

	def delete(path)
		items = scan_path(path)
		name = items.pop # Last is the filename.
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end

		node.delete(name)
		self.save
		rescue Exception => er
			puts "Error! #{er}"
	end

	#==================================
	# ディレクトリを作成するメソッド
	#==================================
	def can_mkdir?(path)
		items = scan_path(path)
		name = items.pop # Last is the filename.
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end
		node.is_a?(Hash)
		rescue Exception => er
			puts "Error! #{er}"
	end

	def mkdir(path)
		items = scan_path(path)
		name = items.pop # Last is the filename.
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end
		node[name] = Hash.new
		self.save
	end

	#==================================
	# ディレクトリを削除するメソッド
	#==================================
	def can_rmdir?(path)
		items = scan_path(path)
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end
		node.is_a?(Hash) && node.empty?
	end

	def rmdir(path)
		items = scan_path(path)
		name = items.pop # Last is the filename.
		node = items.inject(@fs) do |node, item|
			item ? node[item] : node
		end
		node.delete(name)
		self.save
	end
end

if (File.basename($0) == File.basename(__FILE__))
	if (ARGV.size < 2)
		puts "Usage: #{$0} <directory> <yamlfile> <options>"
		exit
	end

	# 引数の情報を格納する
	dirname = ARGV.shift
	yamlfile = ARGV.shift

	unless File.directory?(dirname)
		puts "Usage: #{dirname} is not a directory."
		exit
	end

	root = LaughingFS.new(yamlfile)

	# rootのディレクトリを設定
	FuseFS.set_root(root)
	FuseFS.mount_under(dirname, *ARGV)

	# FuseFSのメインルーチンを実行
	FuseFS.run
end


