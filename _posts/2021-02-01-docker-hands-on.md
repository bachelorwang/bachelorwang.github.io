---
layout: post
title: Docker基礎指令
tags:
  - docker
---

容器技術對於分散式系統、CI/CD非常關鍵，利用 namespaces 與 cgroups 形成 container；在 container 內與原生環境的 process、network、ID、mounted file system 被 kernel 隔離開來，可當作直接利用核心的達成虛擬化的手段。這也是為什麼 Windows 使用 Docker 前必須啟用 WSL。

初學者最容易感到暈頭轉向的就是 image 與 container 的差異。image 相當於 container 的模板，而 container 則是以 image 產生出來的實例。

```shell
docker run alpine
```

當開發者執行這個指令時，意味著「以 alpine 這個 image 建立一個 container」。Docker 被設計得相當方便且直覺，當你的作業環境沒有 alpine 這個 image 時會自動從遠端 pull。

```shell
docker run --rm alpine echo "Hello World"
```

透過 Docker 也能直接執行指令，例如一個傳統印出 `Hello World` 的範例。`--rm` 指的是當 container 離開或 daemon 結束時，這個 container 會自動地被移除。同樣地，這也暗示我們 `docker run alpine` 並沒有移除 container，因此當你再執行：

```shell
docker container ls -a
```

應該能發現一個未被刪除且已經停止的 container。透過 `docker container rm` 並指定 container ID 或名字則能刪除 container。

```shell
docker run --rm --name playground -dit alpine
```

`-d` 為 detach 啟動後則會將執行轉移 background，`-i` 則能夠接受標準輸出入、`-t` 則建立虛擬的 tty 讓容器接受標準輸出入(因此`-it`常常會一起出現)。`--name` 則是讓使用者指定 container 的名稱，畢竟如果每次都要透過 `ls` 來得知 container ID 或 docker 隨機指定的名字則相當不便管理。如果想要連線到該 container 使用 `container attach`，若之前沒有加上 `-t` 的話此方法則行不通。要退出連線而不離開 container 的話必須透過 `Ctrl P,Q` 而非 `exit`。
