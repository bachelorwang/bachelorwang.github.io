# Knuth-Morris-Pratt Algorithm

KMP演算法能進行字串比對，相較於直覺的暴力解 `O(mn)`，KMP的時間複雜度只有 `O(m+n)`。我在學習這個演算法時，一直都沒有看到很好的教學，實際上這個演算法的觀念並不複雜，但不知道為什麼大多的教學都寫得特別長。

KMP的核心觀念在於 failure function，只要搞懂了 failure function，KMP也就懂了。我們先來談談一般直覺的暴力解有什麼問題：參考[Wikipedia](https://en.wikipedia.org/wiki/Knuth%E2%80%93Morris%E2%80%93Pratt_algorithm)的範例我們有兩個字串 `P` `ABCDABD` 與 `S` `ABC ABCDAB ABCDABCDABDE`

```
ABC ABCDAB ABCDABCDABDE
ABCDABD
```

在暴力解時，我們發現 `P[3]` 與 `S[3]` 不符後，又會再一次從 `S[1]` 開始比對：

```
ABC ABCDAB ABCDABCDABDE
 ABCDABD
```

但這完全沒有必要，因為 `P[3]` 與 `S[3]` 不符，那麼 `P[0]`(`A`) 與 `S[1~3]`(`BC `) 的任何一個元素也絕對不匹配。這件事，人類可以透過觀察而迅速得出，但對程式而言要怎麼知道這件事，就是 KMP 演算法的關鍵。

透過 failure function 所產生的 next 表我們能夠知道**在哪失敗應該從哪爬起**。讓我們仔細看看 `P`：

```
ABCDABD
```

當我們在 `P[3]` 比對失敗時，其實還帶出了一個資訊，那就是：`S[0~2]` 與 `P[0~2]`(`ABC`)相等，這並不是一句廢話，如果我們知道 `S[1~2]` 是 `BC`，那我們就沒有必要再從 `P[0]` 開始比對，因為他肯定是錯的，我們只要從 `S[3]` 開始重新與 `P[0]` 比對，就能省去`S[1~2]`的比對步驟。

好，那如果我們在 `P[6]` 比對失敗呢？其實我們只要再從 `P[2]` 開始比對目標字串就行，為什麼呢？**因為我們知道`P[0~1]`與`P[4~5]`等價，如果們我核對過`P[4~5]`，相當於核對了`P[0~1]`。**

而 failure function 的 next 表所記錄的便是 **`P[i+1-F[i]:i+1]`與`P[0:F[i]]`相同的資訊**（白話：子字串 `P[0:i+1]` 的最後 `F[i]` 個字元與起始 `F[i]` 個字元完全相同，又稱為**公共前後綴**）。以`ABCDABD`為例：

```
  A B C D A B D
F 0 0 0 0 1 2 0
```

我們令 `i = 5`，已知`F[i] == 2`，分別輸出`P[i+1-F[i]:i+1]`與`P[0:F[i]]`(也就是`P[4:6]`與`P[0:2]`)可以發現兩個子字串完全相同。那麼這個跳轉表要怎麼使用呢？我們再回頭看看字串比對的步驟。

```
           v     x
ABC ABCDAB ABCDABCDABDE
           ABCDABD
           0000120
```

我們從標示 `v` 的開始比較 `P` 與 `S`，在 `P[6]` 時比對失敗，這時我們就要進行查表，由於我們失敗的是在 `P[6]`，此時必須查看 `F[5]`，透過 `F[5]` 我們可以知道，`P[6]`的前 2 個字元，是與`P[0]`起的 2 個字元相同的(`F[5] == 2`)。所以這時我們要做的事情很簡單，就是把 `P` 的索引換成 `2`：

```
                 v
ABC ABCDAB ABCDABCDABDE
           ABCDABD      before
               ABCDABD   after
```

然後接著從標示 `v` 的位置開始比較，這次我們就能命中自己所想找的子字串。相反的，如果 `P[j]` 還是沒有吻合呢？如果那就不斷地進行 `j = F[j - 1]` 的動作，直到 `j == 0`，如果`P[0]`還是不吻合，代表我們需要移動 `S` 的當前索引。上述行為可以表達為下列程式碼：

```python
f = build_failure(p)
i = 0
j = 0
while i < len(s):
    if p[j] == s[i]:
        i += 1
        j += 1
    elif j:
        j = f[j - 1]
    else:
        i += 1
    if j == len(p):
        return i - j
return -1
```

那麼該怎麼建立 failure function，其實作法有點類似，我們只需要拿 `P` 與 `P` 自己做比較就可以。

```python
v
ABCDABD
 ABCDABD
 ^
00
```

`P[0]` 與 `P[1]` 不同，代表如果我們在 `P[2]` 比對失敗時，還是要從`P[0]`起重新比對。以此類推進行至 `P[4]`。

```python
    v
ABCDABD
    ABCDABD
    ^
00001
```

`P[0]` 與 `P[4]` 相同，此時我們為`F[4]`填入 `1`，代表`F[4:5] == F[0:1]`，以此類推：

```python
     v
ABCDABD
    ABCDABD
     ^
000012
```

`P[1]` 與 `P[5]` 相同，此時我們為`F[5]`填入 `2`，代表`F[4:6] == F[0:2]`。當比較到`P[6]`時與`P[2]`不吻合，根據`F`我們再往後退，以`P[1]`與`P[6]`比還是不吻合，再往後退，`P[0]`與`P[6]`依然不吻合，建表結束。

```python
def build_failure(s: str):
    n = len(s)
    i = 1
    c = 0
    ans = [0] * n
    while i < n:
        if s[i] == s[c]:
            c += 1
            ans[i] = c
            i += 1
        elif c:
            c = ans[c - 1]
        else:
            i += 1
    return ans
```
