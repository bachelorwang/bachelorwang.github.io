---
layout: post
title: Docker + Jekyll = an easy way to create Github Pages blogger
tags:
  - docker
---

[Github Pages](https://pages.github.com/)省下不少人架設個人伺服器的時間與金錢，然而要做出一個兼具結構與美觀的靜態網站仍需下一番苦工。雖然從頭到撰寫 HTML 與 css 也是一種做法，但不少人會採用 Generator 產生靜態頁面，其中又以 Github 內建支援的 [Jekyll](https://jekyllrb.com/docs/) 成為首選。

但恐怕不少人會被 Jekyll 繁瑣的步驟給勸退，而我就是其中之一(畢竟我實在不想在工作環境裡安裝Ruby)。我想這時候就輪到 Docker 出場了。

```shell
docker run --volume="${PWD}:/srv/jekyll" --rm jekyll/jekyll jekyll new <RELATIVE_PATH>
```

`--volume="${PWD}:/srv/jekyll"` 會將我們當前的工作路徑掛載到 container 中的 `/srv/jekyll`，你可以根據自己的計畫調整相關引數。透過這道指令可以馬上建立一個 Jekyll 網站所需要的原始碼，至於怎麼在 Github 建立 Pages 所需要的 Repositry 可以參考[官方教學](https://docs.github.com/en/github/working-with-github-pages/creating-a-github-pages-site-with-jekyll#creating-a-repository-for-your-site)。

當你產生Jekyll專案目錄後，還必須註解掉 Gemfile 中的 `gem "github-pages", group: :jekyll_plugins`，並把參考[官方清單](https://pages.github.com/versions/)將 `gem "jekyll", "~> <VERSION>"` 或其他的 Dependency 修改為適當版號。

每當我們要開始撰寫網站時，只要執行：

```shell
docker run \
  --rm -d --volume="${PWD}:/srv/jekyll" \
  -p 80:4000 jekyll/jekyll \
  jekyll serve --force_polling
```

就能在 local 直接觀察編輯結果。

但，這樣還是有個大問題，那就是**太慢了！**  
每次我們啟動這個 container 就會進行一次 Gem 的安裝，有什麼辦法可以避免這樣的狀況呢？其實我們只要建立自己的 Jekyll image 就可以了。

```docker
FROM jekyll/jekyll

COPY Gemfile Gemfile.lock /srv/jekyll/
RUN bundle install
```

以此 Dockerfile 建立 image 我們就得到一個已經安裝相應 Gemfile 套件的映象檔，也讓未來的執行更加愜意。

> 如果你很確定不會再更改 Jekyll 的 port 也能直接加上 `EXPOSE 4000`
