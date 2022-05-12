最近開始看 Google 的 [abseil](https://github.com/abseil/abseil-cpp) 庫，若從容器看起應該會遇到 `Layout`。這是 absl 庫內部用來輔助記憶體計算的工具，探討 `Layout` 前我們要討論在開發上我們經常遇到什麼重複性作業。

```cpp
struct SomeStructure {
  int32_t start;
  int32_t end;
  int32_t height;
  double distance;
};
```

C++ 開發時，我們經常會採用預先配置大量記憶體的策略，在日後如果需要配置零碎的小物件時，我們只要知道小物件的記憶體空間，向記憶體管理器的註記對應大小的記憶體，就不用再透過動態配置的行為重新要求動態配置。不過不少工程師會算錯記憶體，例如 `SomeStructure`：

1. `SomeStructure`的大小是多少呢？
2. `distance` 在該結構中的 offset 為何？

心想 `int32_t` 為 4 bytes，`double` 為 8 bytes，那麼 `SomeStructure` 的大小應該是 4 * 3 + 8 吧？那麼就錯了，因為編譯器實作為了優化存取，會對結構進行 alignment。在這個狀況下會取結構中欄位 alignment 最大的作為 alignment 的單位。在一些編譯器上，這個 alignment 可以由程式設計師決定，例如 `#pragma pack(1)` 就是一種取消 padding 使結構緊密的作法。

確實，大部分的狀況下我們都會直接用 `sizeof` 取得結構的大小。但若我們不想定義結構呢？如果我們希望將資料結構的描述作為資料結構表示，意味著它是可透過模板生成的可複用程式碼，該怎麼做呢？ absl 的 `Layout` 提供了一種解決方案。

我們可以看看 absl 的 [btree](https://github.com/abseil/abseil-cpp/blob/master/absl/container/internal/btree.h)：

```cpp
  using layout_type = absl::container_internal::Layout<btree_node *, field_type,
                                                       slot_type, btree_node *>;
  // Leaves can have less than kNodeSlots values.
  constexpr static layout_type LeafLayout(const int slot_count = kNodeSlots) {
    return layout_type(/*parent*/ 1,
                       /*position, start, finish, max_count*/ 4,
                       /*slots*/ slot_count,
                       /*children*/ 0);
  }
  constexpr static layout_type InternalLayout() {
    return layout_type(/*parent*/ 1,
                       /*position, start, finish, max_count*/ 4,
                       /*slots*/ kNodeSlots,
                       /*children*/ kNodeSlots + 1);
  }
```

`layout_type(1, 2, 3, 4)` 代表這個記憶體中第一個欄位型別是`btree_node *`、第二至三個欄位型別是 `field_type`，以此類推…… constructor 傳入的參數代表 template parameter 對應位置的型別依序共有幾個欄位。因此這個物件共有 10 個欄位。`Layout` 避免程式設計師為了效能、客製化撰寫過多相似又關係複雜的型別，提供介面便於開發者直接對記憶體進行操作、並避免工程師在處理 alignment、size 計算上花費太多心思。

就樹來說，至少 leaf 不須紀錄 `children` 而節點的數量也可以再作調整。對於中間的節點來說就必須記錄子節點的數量。此時沒有必要進行再設計`LeafLayout` 與 `InternalLayout`。若要再舉一個更簡單的例子，想想若要設計二維向量、三維向量的結構會怎麼做？也許我們可以透過 `std::tuple`，但若能夠 in-place 只是將 `Layout` 切換是否更簡便？

`Layout`的實作用上了不少 template 的技巧，我這邊寫了一個迷你版的：

```cpp
template <size_t Size>
using index_to_size = size_t;

static constexpr size_t align(size_t n, size_t m) {
  return (n + m - 1) & ~(m - 1);
}

template <typename TElements, typename TSizeIndexes>
struct layout_impl;

template <typename... TElements, size_t... TSizeIndexes>
struct layout_impl<std::tuple<TElements...>,
                   std::index_sequence<TSizeIndexes...>> {
  enum {
    NumTypes = sizeof...(TElements),
    NumSizes = sizeof...(TSizeIndexes),
  };

  static_assert(NumTypes > 0);

  constexpr explicit layout_impl(index_to_size<TSizeIndexes>... sizes)
      : sizes_{sizes...} {}

  using element_types = std::tuple<TElements...>;

  template <size_t TIndex>
  using element_type = std::tuple_element_t<TIndex, element_types>;

  template <size_t TIndex>
  using element_alignment = std::alignment_of<element_type<TIndex>>;

  static constexpr size_t alignment() {
    return ::wutils::max(element_alignment<TSizeIndexes>::value...);
  }

  template <size_t TIndex, std::enable_if_t<TIndex == 0, int> = 0>
  constexpr size_t offset() const {
    return 0;
  }

  template <size_t TIndex, std::enable_if_t<TIndex != 0, int> = 0>
  constexpr size_t offset() const {
    return align(offset<TIndex - 1>() +
                     sizeof(element_type<TIndex - 1>) * sizes_[TIndex - 1],
                 element_alignment<TIndex>::value);
  }

  constexpr size_t alloc_size() const {
    return offset<NumTypes - 1>() +
           sizeof(element_type<NumTypes - 1>) * sizes_[NumTypes - 1];
  }

 private:
  size_t sizes_[sizeof...(TElements)];
};
```

值得注意的技巧有兩個，首先偏移量、大小的計算若能在編譯時期完成那是在好不過的，我們也不想造成 runtime 時額外的成本。因此 `layout_impl` 的 constructor 必須有 `constexpr` 修飾。第二是至關重要的欄位偏移量，相較 `std::tuple`，`Layout` 允許每個型別具有數個欄位，數量的差異外加 alignment 的考量讓偏移量的計算複雜起來。

```cpp
  template <size_t TIndex, std::enable_if_t<TIndex == 0, int> = 0>
  constexpr size_t offset() const {
    return 0;
  }

  template <size_t TIndex, std::enable_if_t<TIndex != 0, int> = 0>
  constexpr size_t offset() const {
    return align(offset<TIndex - 1>() +
                     sizeof(element_type<TIndex - 1>) * sizes_[TIndex - 1],
                 element_alignment<TIndex>::value);
  }
```

`Layout`為 `offset` 定義了兩個版本，第一是起點，也就是第一種資料型別的欄位起始偏移量理所當然為 0。如果是第 N 個型別，必須是 N - 1 型別的起始偏移量加上 N - 1 型別的容量乘以數量，最後再與 N 型別進行 align。這便是 meta-programming 基本的遞迴技巧之一。
