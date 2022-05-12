---
layout: post
title: next_permutation
tags:
  - c++
  - algorithm
---

`std::next_permutation`是 STL 中將容器排序為下一個排列次序的函數，不過究竟何謂下一個排列究竟是依什麼規則而產生，不理解其實作原理的人恐怕難以想像。`next_permutation`有一個隱晦的規則，恰好能說明其實作原理，那便是如果你要透過此函數列舉所有元素排列的可能，那麼一開始容器必須要處於**「已經排序」**的狀態。而`next_permutation`回傳 `false` 表示已無次組排列次序可列舉。實際上，這個**最後一個排列次序**正是**「倒序」**。例如：

```
1 2 3 4 5 6
```

是集合`{1, 2, 3, 4, 5, 6}`的第一個排序次序，而

```
6 5 4 3 2 1
```

則是最後一個排序。`next_permutation`的實作規則，其實是將大問題遞迴切割為小問題，大問題是**索引`[a, c]`且`a < c`的元素是否已為倒序**，小問題是**索引`[b, c]`且`a < b < c`的元素是否已為倒序**。當子問題已解代表子序列已為倒序，若索引`a`的元素次序低於索引`b`的元素，則將索引`a`元素與`[b, c]`中右起第一個次序高於其的元素交換，並反轉排列`[b, c]`的子序列。簡而言之`next_permutation`不停地從未至首檢視序列是否為倒序，若遇到不滿足倒序的元素，則將該元素與子序列中的上限元素交換，再將右側序列反轉排列。

```
2 3 4 5 3
```

則會變為

```
2 3 5 3 4
```

現在我們來看看微軟的 STL 的實作。


```cpp
template <class _BidIt, class _Pr>
_CONSTEXPR20 bool next_permutation(_BidIt _First, _BidIt _Last, _Pr _Pred) {
    _Adl_verify_range(_First, _Last);
    auto _UFirst      = _Get_unwrapped(_First);
    const auto _ULast = _Get_unwrapped(_Last);
    auto _UNext       = _ULast;
    if (_UFirst == _ULast || _UFirst == --_UNext) {
        return false;
    }

    for (;;) {
        auto _UNext1 = _UNext;
        if (_DEBUG_LT_PRED(_Pred, *--_UNext, *_UNext1)) {
            auto _UMid = _ULast;
            do {
                --_UMid;
            } while (!_DEBUG_LT_PRED(_Pred, *_UNext, *_UMid));

            _STD iter_swap(_UNext, _UMid);
            _STD reverse(_UNext1, _ULast);
            return true;
        }

        if (_UNext == _UFirst) {
            _STD reverse(_UFirst, _ULast);
            return false;
        }
    }
}
```

首先會先對容器的大小進行檢查，對於空序列或只有單一元素的序列而言，自然就沒有下一個排序可言。

```cpp
    if (_UFirst == _ULast || _UFirst == --_UNext) {
        return false;
    }
```

確認容器大小以後，便會正式進入演算法的主流程。

```cpp
    for (;;) {
        auto _UNext1 = _UNext;
        if (_DEBUG_LT_PRED(_Pred, *--_UNext, *_UNext1)) {
            //
        }
        if (_UNext == _UFirst) {
            _STD reverse(_UFirst, _ULast);
            return false;
        }
    }
```

這裡可以看出 STL 實作的另一個精妙之處。直覺地寫，一般我們會先透過迴圈找出倒序子序列的起點，但STL並不這麼做，而是透過一個無窮迴圈每次檢查左元素次序是否低於右元素，並且往左移動，如果移動至序列最左端，則表示整個序列皆已為倒序，並將序列還原為已排序狀態並回傳已無排列可再列舉。

```cpp
        if (_DEBUG_LT_PRED(_Pred, *--_UNext, *_UNext1)) {
            auto _UMid = _ULast;
            do {
                --_UMid;
            } while (!_DEBUG_LT_PRED(_Pred, *_UNext, *_UMid));

            _STD iter_swap(_UNext, _UMid);
            _STD reverse(_UNext1, _ULast);
            return true;
        }
```

當左元素不小於右元素時，再尋找子序列右起的上限元素兩者交換，再將子序列反轉。

[cppreference](https://en.cppreference.com/w/cpp/algorithm/next_permutation)有列出一個更簡便的寫法，那就是充分利用 STL 的函數完成一連串的操作。

```cpp
template<class BidirIt>
bool next_permutation(BidirIt first, BidirIt last)
{
  auto r_first = std::make_reverse_iterator(last);
  auto r_last = std::make_reverse_iterator(first);
  auto left = std::is_sorted_until(r_first, r_last);
  if(left != r_last){
    auto right = std::upper_bound(r_first, left, *left);
    std::iter_swap(left, right);
  }
  std::reverse(left.base(), last);
  return left != r_last;
}
```

先將容器的 `iterator` 顛倒過來，以顛倒方向進行操作，並且找出第一個使序列不滿足倒序的元素。大部分正式的 STL `next_permutation` 的實作其實都差不多，但不使用與 cppreference 所寫可讀性較高的寫法，一般是考量到效能。透過解讀原始碼，我們也了解了 STL 是如何完成全排序列舉。
