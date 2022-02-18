---
layout: post
title: 論重構 02
tags:
  - refactoring
---

## 怎樣的程式碼需要重構

出師有名，重構通常需要有個理由，有時候更需要有一個好理由才能說服公司投注金錢與時間。我們不為重構而重構，因為任何一段程式碼總是有辦法寫成另一種形式，就像那句 Perl 的俗諺：

>> There's more than one way to do it.

如果你正在寫 Python，而剛好那段程式碼又符合 Python 的俗諺，那似乎更沒有理由去重構。

>> There should be one-- and preferably only one --obvious way to do it.

因此那些需要被重構的程式碼，總是具備某些令人厭惡的特徵讓你萌生重構的念頭。

### 重複的程式碼

重複的程式碼必須被重構的理由在先前的文章已說過，大多數的人以為複製程式碼能夠保留原本功能的正確性，我認為這是一種不負責任的說法。重複的程式碼使軟體行為不一致的風險提高，更提高了維護的成本。被複製的副本越多份，就使得日後它們被合併的成本越高。期望所有的錯誤都被同步修正、正確地修正，也是不切實際的期望。如果你發現重複的程式碼，應該要盡早的合併它們。

### 瑞士刀

我們總是喜歡瑞士刀，付一個工具的價格，得到複數個工具的功能。這樣的工具在現實世界或許是主流，我們總是能看到不少多合一、多用途的工具放在貨架上。然而專業領域中，不同的問題需要不同的工具，大眾的家庭廚房恐怕就不只一種刀具了，更何況是餐廳。然而程式碼中，我們卻經常見到如同瑞士刀般的程式碼。一個 function 可能執行了多種計算以至於它長達百行的空間，又或是一個 class 具備了數十種 method。

clean code 建議我們一個 function 不超過 9 行，這並不是一個鐵則，而是一種指導原則，要求我們讓一個 function 盡其所能的「只做一件事」。有人會問：「瑞士刀般的程式碼為何需要改進？」試想如果你的瑞士刀其中一個小工具壞了，你會怎麼做？我相信很少有人會把其中一個小工具換下來，即使你有的更換的零件。在軟體工程中，這個問題更顯得複雜，一個工程師必須識別這個 function 或 class 到底哪個段落出了問題，閱讀與除錯耗費我們職涯中許多時間，我們不會希望再把這些成本加劇。讀十行程式碼總是比讀一百行程式碼容易。

這個指導原則，其實就是大家常說的 single-responsibility principle。

### 隱晦的規則與行為

你可曾聽到：「這個 function 的第五個引數在第二個引數不為某某值時是沒用的」或「傳入這個 function 的物件必須要依序經過一些額外步驟設定，他的行為才會如你預期」或「在使用這個 class 前要先將某某全域變數設定為某某值，記得呼叫結束後要將全域變數還原」這些論述都暗示了一件事，那就是當前這個模組難以維護與使用。隱晦的行為與規則通常是由耦合性過高與錯誤的抽象層級、不適當的介面設計造成。我們都聽過 the least knowledge principle，LKP 往往被忽略，那是由於我們的工作模式與環境。

一般來說，我們會認為一個員工應該認得他職責範圍內的程式碼，甚至是整個團隊、整個產品的程式碼。  
「如果你不知道，可以問人。」  
然而當你 blame 時，並不是所有 commit 的 author 都還留在公司，甚至有些開發者已經忘記自己當時為何要這樣寫。我們看得到所有的程式碼，卻不代表我們擁有該程式碼所有的知識。在這種狀況下，LKP 其實要我們考慮的是使用程式碼的人。那些過於複雜、耦合性過高的程式碼會有這些特徵：

- 需要依賴大量的模組
- 需要許多的參數或步驟才能使用
- 特定的狀態或使用情境導致錯誤但不易察覺