NVIDIA醞釀已久的 Omniverse 在2020/12/15終於開放 Beta 測試，Omniverse 最為人注目的應該是他的協作(collaboration)與渲染(rendering)能力。然而要踏入 Omniverse 需要不少先備知識，在此──套O'Reilly最常見的標題──「深入淺出」希望能讓讀者盡早融入 Omniverse 龐大的體系。

#### Omniverse 到底是什麼？

Omniverse 是一個 Platform(平台)，志在提供強大的渲染、協作與模擬能力。Omniverse 能運用在建築業、動畫產業、遊戲業甚至是工業([BMW例子](https://blogs.nvidia.com.tw/2020/05/15/bmw-group-selects-nvidia-to-redefine-factory-logistics/))上。雖然宣傳詞聽來包山包海，但如果你理解 Omniverse 的生態系與原理，也就能明白 NVIDIA 的野心。

#### Omniverse 為何會與皮克斯的 Universal Scene Description(USD) 掛勾？

USD要翻譯的話，可翻作通用場景描述格式；確實不管是作為美術還是軟體設計師，都希望只要有一個格式就能在所有軟體間共同作業，我們有 FBX、DAE、STL、3DS、OBJ、GLTF 甚至是一些特殊工具自製的格式都為了去描述 3D Model 或場景。我們必須認清：沒有銀彈(silver bullet)。既然如此 USD 要如何肩負 Universal 這個重擔？USD 具備兩個重要的能力，其中之一是 **Plugin**。

我相信許多創作者都有同份檔案在不同軟體甚至是同產品不同版本間開啟會有不同結果的經驗，就像一本書所有人讀完解釋都有不同的結果，檔案格式也會根據軟體不同而有不同的解釋(盡管大家都想努力遵從標準)。但這也提供我們一個很重要的發想，那就是我們不需要「一個能被所有軟體解讀的檔案格式」而是「**一個能描述所有事物的檔案格式**」。聽起來像是在玩文字遊戲，但這正是 USD 正在做的事。

舉例來說，你可以在 USD 內使用一個 OBJ 檔作為你的 Model，聽起來很不可思議嗎？因為解讀 USD 是軟體必須做的事，如果你需要解讀非 USD 標準所描述的額外資訊，你就需要相應的 Plugin，就像 Pixar 官方提供的範例 [usdObj](https://github.com/PixarAnimationStudios/USD/tree/release/extras/usd/examples/usdObj) 一樣。NVIDIA 就為 USD 寫了 MDL 的 Plugin，讓 MDL 可以在 USD 場景中被使用。這也就是 USD 能夠無限地擴充的緣故。

而另一個能力則是協作能力：composition arc。這個協作與 Omniverse 本身的協作機能不同，是 USD 格式本身具備的描述能力。舉例來說，當多個創作者同時在編輯一個 3D Model 時，這個 3D Model 可以被拆分成多份檔案，每份檔案都能夠獨立或組合地作業，而不需要擔心造成 conflict。

#### Omniverse 為何足以稱作一個平台？

Omniverse 提供整個開發生態系，適合企業、工作室、創作者、程式設計師參與。任何人都可以架設自己的 Nucleus 伺服器提供其他人以 Connector 或傳統檔案傳輸共同作業，任何人都能使用現成的 Omniverse 應用程式，任何人都可以下載 SDK 開發應用程式。傳統的作業流程：當你建立一個場景時，必須先把素材準備好，如果素材更新了則需要重新匯入。在 Omniverse 體系中，只要所有的工具都透過 Connector 連線到 Nucleus 上就能同時作業，例如同時進行材質貼圖編輯、場景調整等。

由於 USD 是一個 Open-Source 的格式，這使得軟體開發者相當易於撰寫格式轉換，也不必擔心自己既有的檔案必須全部被改成 USD；如果你使用的軟體能直接擴充 USD 支援既有的檔案格式那就更棒了。

#### 程式設計師如何開始學習 USD

USD功能開發目前有兩種環境，一種是透過 Python 一種是透過 C++。以 Python 進行 USD 開發的優點是官方範例很多，而且 Omniverse Kit 的開發環境主要也以 Python 為主，缺點我還真的想不到，除非你真的是超級硬派的開發者，那麼 Python 就足以應付 80% 的開發了。至於 C++ 則是一條荊棘之路，C++ 適合原本項目的 library 就是以 C++ 開發的或志在提供 Plugin，也能夠作 binding 給 Python。對一般開發者而言，只要把[官方教學](https://graphics.pixar.com/usd/docs/USD-Tutorials.html)跑過一輪就可以大致理解 USD 的術語與結構。

#### 程式設計師如何開始學習 Omniverse

學習 Omniverse 前，建議必須先對 USD 有一定的掌握。畢竟 USD 是 Omniverse 資料的主要載體、編輯對象。Omniverse 必須下載 Omniverse Kit 透過 Python 來進行開發。如果你野心勃勃想寫自己的 Connector，可以下載 Connector Sample 並使用裡面分別編譯好的 Release/Debug library。
