#!/usr/bin/ruby

require 'imlib2'
require 'tempfile'
 
#TODO
#================================================================================================

class LaughingEngine

	# コンストラクタ
	# path:格納する画像のパス
	# pos:デフォルトのオフセット
	def initialize(image_path = nil, pos = nil)

		# ファイル書き込み用一時ファイル
		@tmpfile = Tempfile.new("LaughingEngine")

		# 画像のパス保存
		if(image_path == nil)
		then
			@imgpath = "/home/shimada-k/laughing_man.png"
		else
			@imgpath = image_path
		end

		# オフセットの初期化
		pos ? @curr_pos = pos : @curr_pos = 0

		#printf("curr_pos is %d\n", @curr_pos)
	end

	# bodyは画像にセットするテキスト
	# return:bodyをセットした後の画像のバイナリデータ
	def write(body)

		img = Imlib2::Image.load(@imgpath)

		#==============================================
		#画像の0画素目に書き込むデータ量を格納する
		#==============================================
		pxl = img.pixel(0, 0)

		pxl.r = (body.length & 255)
		pxl.g = (body.length >> 8) & 255
		pxl.b = (body.length >> 16) & 255

		img.draw_pixel(0, 0, pxl)

		@curr_pos += 1

		even = body.length / 3
		odd = body.length % 3

		pos_x = @curr_pos % img.w
		pos_y = @curr_pos / img.w

		#printf("body.length = %d\n", body.length)

		#===========================================
		#1画素をきっちり埋められる分だけループする
		#===========================================
		i = 0

		while(i < even * 3)
			pxl.r= body[i]
			pxl.g = body[i + 1]
			pxl.b = body[i + 2]
			i += 3

			img.draw_pixel(pos_x, pos_y, pxl)
			@curr_pos += 1

			# x座標、y座標を再計算
			pos_x = @curr_pos % img.w
			pos_y = @curr_pos / img.w
		end

		#=============================================
		# 文字列長が3で割り切れなかった時の端数を処理する
		#=============================================
		pxl = img.pixel(pos_x, pos_y)

		if(odd == 1)
		then
			pxl.r = body[i]
		elsif(odd == 2)
		then
			pxl.r = body[i]
			pxl.g = body[i + 1]
		end

		img.draw_pixel(pos_x, pos_y, pxl)

		# 画像を一時ファイルとして書き込む
		img.save(@tmpfile.path)

		# 書き込んだ内容を返す
		@tmpfile.rewind		# ファイルポインタを先頭に戻す
		@tmpfile.binmode

		#[@tmpfile.read].pack('m')	# base64でエンコーディングされたテキストを取得するとき
		@tmpfile.read

	end

	# 画像データからバイトデータを取り出すメソッド
	# bin:バイナリ状態の画像データ
	# return:テキスト
	def read(bin)

		#==========================================
		#バイナリ形式のデータを一時ファイルに書き込む
		#==========================================
		@tmpfile.binmode
		@tmpfile.write bin

		#printf("一時ファイルの書き込み終了:%s\n", @tmpfile.path);

		#バイナリ形式から画像フォーマットで保存したデータをオブジェクトとして取得
		@tmpfile.rewind
		img = Imlib2::Image.load(@tmpfile.path)

		#========================================================
		#画像の先頭1画素からどこまで何バイト書き込んであるか取得する
		#========================================================

		p0 = img.pixel(0, 0)
		len = (p0.b << 16) | (p0.g << 8) | p0.r

		printf("length = %d\n", len)

		@curr_pos += 1
		i = 0

		# x座標、y座標を再計算
		pos_x = @curr_pos % img.w
		pos_y = @curr_pos / img.w

		buffer = String.new()

		even = len / 3
		odd = len % 3

		#===========================================
		#1画素をきっちり読み取れる分だけループする
		#===========================================
		while(i < even)

			pxl = img.pixel(pos_x, pos_y)
			#printf("(R, G, B)@(X, Y) = (%d, %d, %d)@(%d, %d)\n", pxl.r, pxl.g, pxl.b, pos_x, pos_y)

			buffer.concat(pxl.r)
			buffer.concat(pxl.g)
			buffer.concat(pxl.b)
			i += 1

			@curr_pos += 1

			# x座標、y座標を再計算
			pos_x = @curr_pos % img.w
			pos_y = @curr_pos / img.w
		end

		#=============================================
		# 文字列長が3で割り切れなかった時の端数を処理する
		#=============================================
		pxl = img.pixel(pos_x, pos_y)

		if(odd == 1)
		then
			buffer.concat(pxl.r)
		elsif(odd == 2)
		then
			buffer.concat(pxl.r)
			buffer.concat(pxl.g)
		end

		printf("buffer Is...\n")
		print buffer
		printf("\nend of buffer\n")

		buffer
	end
end

=begin
str = String.new()

str = "J.D.サリンジャー。1919年1月1日にニューヨークで生まれた。父方はユダヤ人、母方はスコッチ・アイリッシュ。学校生活は「ライ麦のホールデン少年のように」転々と転校を繰り返し、その中にはコロンビア大学で短編小説の修業をしたことなどが特徴として挙げられる。陸軍学校を卒業後は、第二次世界大戦にてイギリスで諜報活動の訓練を受けた後、ノルマンディ上陸作戦へ参加した。これは同じく彼の「エズミに捧ぐ」のX曹長なる人物に酷似しているようにも思われ、彼がいかに事実に忠実に基づき作品を仕上げたかがうかがえる。これは彼の作品にたびたび登場するニューヨークのバーや洋服店、ホテルなどそういったものからも、彼の生まれ故郷もニューヨークだったことを思い出せば、いかに事実に基づいているかがわかると思う。彼は1940年に「若者たち」を発表し、第二次大戦中にも執筆を続け、50年には「ライ麦畑でつかまえて」を発表。この作品が賛否両論で、一躍注目の的となったサリンジャーは、53年には自薦短編集の「ナインストーリーズ」を発表している。がその後しばらくの沈黙を続け、再び表に表れたのは「フラニー」から始まるグラース家の物語をシリーズとして発表したとき。以後はこのグラース家についての誰かをテーマに置いた作品を続けると発表し、55年に「フラニー」「大工よ、屋根の梁を高く上げよ」、57年に「ゾーイー」、59年に「シーモア－序章－」と続いたが、65年に「1924年ハプワス16日」を発表したのが最新で、それからは全く新作は無く、音沙汰すら無い。さらにはサリンジャーは、翻訳版をむやみに出されることすらも頑なに拒否し、自身の写真を用いることも最初は禁止としていた。"

str = "I stand here today humbled by the task hoge is not oge"

w = LaughingEngine.new()
w.write(str)

w.read(2082)
=end

