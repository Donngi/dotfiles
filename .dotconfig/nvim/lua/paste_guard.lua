-- 巨大テキストの貼り付けでターミナルごとフリーズするのを防ぐ。
--
-- 症状: cmux (libghostty) のターミナルで 30KB 程度のテキストを Cmd+V すると、
--       nvim が完全に固まり、待っても戻らず強制終了しか無くなる。
--       ウィンドウを分割 (:new) していると再現率が上がる。`nvim --clean` でも起きるので
--       このリポジトリの設定が原因ではない。
--
-- 原因: pty のフロー詰まり (デッドロック)。
--   1. ターミナルは bracketed paste で 30KB を pty に書き込む。
--   2. nvim は貼り付けをチャンク (約 17 行ずつ) に分けて vim.paste() に渡し、
--      チャンクごとに画面を再描画して pty へ描画バイトを書き出す。
--   3. ターミナルが「貼り付けを書き込んでいる間その pty の出力を読まない」実装だと、
--      nvim の出力で pty のバッファが埋まり、nvim は write 待ち (flush_buf) で停止する。
--   4. 停止した nvim は入力も読まないので、ターミナル側の残りの書き込みも止まる。
--      互いに待ち合って永久に解けない。
--
--   実測: 30,405 バイトの貼り付けを「書き込み中に読まない」条件で流すと、
--   2KB ほど書けたところで停止し、残り 28,361 バイトが永久に書けなくなる。
--   同じ貼り付けを「読みながら書く」条件で流すと 10 秒以内に完了する。
--
-- 対策: 貼り付けの途中で nvim が出力を出さないようにする。
--   チャンクを溜めて最後に一度だけ適用すれば、貼り付け中の再描画が無くなるので
--   pty のバッファが埋まらず、ターミナルは書き込みを終えられる。
--   実測: 貼り付け中の nvim の出力が 20,519 バイト → 2,867 バイトに減り、
--   「書き込み中に読まない」条件でもデッドロックしなくなる。
--   normal / insert どちらのモードでも、貼り付け結果はバイト単位で元テキストと一致する。
--
-- 注意: 根本原因はターミナル側にあるので、これは緩和策である。
--       貼り付けが完了するまで画面が更新されない (巨大なテキストでは一瞬待たされる)。

local M = {}

function M.setup()
	local orig = vim.paste
	-- 溜めている途中のチャンク。貼り付けが中断されたら次の phase 1 で捨てられる。
	local acc = nil

	vim.paste = function(lines, phase)
		-- phase -1 は分割されていない単発の貼り付け。溜める必要がない。
		if phase == -1 then
			return orig(lines, phase)
		end

		if phase == 1 then
			acc = {}
		end

		-- 何らかの理由で phase 1 を受け取っていないときは素通しする (壊さない方を選ぶ)
		if acc == nil then
			return orig(lines, phase)
		end

		if #acc == 0 then
			vim.list_extend(acc, lines)
		else
			-- チャンクの境界は行の途中で切れることがあるため、
			-- 前のチャンクの末尾と今回の先頭を連結する (vim.paste の charwise 相当)。
			acc[#acc] = acc[#acc] .. lines[1]
			for i = 2, #lines do
				acc[#acc + 1] = lines[i]
			end
		end

		if phase == 3 then
			local all = acc
			acc = nil
			-- 単発の貼り付けとして一度だけ適用する
			return orig(all, -1)
		end

		-- まだ続きがある: true を返して次のチャンクを受け取る
		return true
	end
end

return M
