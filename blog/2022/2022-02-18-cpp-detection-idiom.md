不少人應該都聽過 SFINAE ─ "Substitution Failure Is Not An Error"，中文直翻就是「替換失敗不是一個編譯錯誤」。這個編譯器規則，進而產生了許多有用 metaprogramming 有用的技巧。

舉例來說：

```cpp
template<typename T>
auto foo(T a) -> decltype(a.f()) {
    a.f();
}

template<typename T>
auto foo(T a) -> decltype(a.g())  {
    a.g();
}

struct A {
    void f() { std::cout << 'a'; }
};

struct B {
    void g() {std::cout << 'b';}
};

int main()
{
    A a;
    B b;
    foo(a);
    foo(b);

    return 0;
}
```

編譯器實際上會對所有名為 `foo` 的 template function 進行一次 substitution，也就是 template 參數的帶入。對編譯器來說，`struct B` 帶入第一個 signature 失敗時，不應馬上產生編譯錯誤，而是應該要繼續嘗試下一個。當所有的 signature 都失敗時，才是真正的編譯錯誤。主流編譯器通常會明確列舉他在帶入時是哪些條件使得替換無法成功，以便開發者進行修正。

然而知道這個技巧，並不能說明要怎麼利用他。如果一個程式技巧不常使用，久而久之就會生疏。 C++11 引入了 enable_if，使得很多初學者看了仍不明白這個 trait 的用途。這個困擾，我有一個簡單的例子可以說明。我們可以想像一個情境，假設有一個 generic container 需要對所有元素進行釋放，這時我們會怎麼寫？

```cpp
template <typename T>
struct List
{
    T* elements;
    size_t count;

    bool alloc(size_t);

    void free()
    {
        if (elements)
            ::free(elements);
        count = 0;
        elements = nullptr;
    }
};
```

`free` 有一個嚴重的錯誤，不知道你注意到了沒？ `free` 的錯誤在於他只對記憶體進行了釋放，這只有在 `T` 是 POD 的狀況下才是正確的。那麼要怎麼樣處理這個問題呢？我們是否應該再寫一個新的 method 例如 `free_non_pod_elements` 呢？這麼一來，對使用者來說無疑增添了疑惑與困擾。更好的方法是透過 SFINAE 技巧。

```cpp
template <typename T, typename = std::enable_if_t<std::is_trivially_destructible_v<T>>>
struct List {
  // ...
};
```

`enable_if_t` 就是 SFINAE 技巧的運用法之一，

```cpp
template<bool B, class T = void>
struct enable_if {};
 
template<class T>
struct enable_if<true, T> { typedef T type; };
```

只有條件為 `true` 的時候，`enable_if` 才會有 `type` 這個 member。套用 SFINAE 的邏輯，任何帶入 `List` 的 `T` 都必須滿足 `is_trivially_destructible_v` 的條件。這種寫法，讓我們強制了 List 對型別的約束只能是 trivially destructible 的型別。那麼如果我們要同時滿足 non-trivial 的型別呢？這時反而比較簡單，就是透過 specialization，這反而是 template 中一個比較基本的技巧，在此就不多做介紹。 metaprogramming 的基礎，就是在於不斷定義 trait 組合出程式碼。

這在 C++20 做起來很簡單，不幸的是，並不是每間公司都能用上 C++14、17 以上的版本。甚至我目前的工作環境，就無法使用完整的 C++11。針對那些非 stl `type_traits` 定義的 trait 或想要達成類似 C++20 concept 的人來說，就要繞一些遠路。今天最主要要介紹的，其實是 C++ 的 detection idiom。

detection idiom 的用途是：我們是否能夠自行定義 trait 判斷該型別是否符合我們需要的條件。例如我們想要判斷一個型別是否具備名為 `free` 的 method，方法很簡單，我們要先定義一個 trait class，如下：

```cpp
template <typename T>
struct is_custom_free
{
    static const bool value = decltype(has_free<T>(NULL))::value;
};
```

這時編譯當然不會過，但我們只要完成 `has_free` 這個 function 即可。首先對於那些不符合條件的型別，我們只要定義它的 return type 是 std::false_type 就可以。對於編譯器來說，不符合條件的型別就會自動套用這個 overload 的結果。

```cpp
template <typename T>
struct is_custom_free
{
    template <typename U>
    static std::false_type has_free(...)
    {
        return {};
    }

    static const bool value = decltype(has_free<T>(NULL))::value;
};
```

符合的狀況，也就是 std::true_type 則略顯複雜：

```cpp
template <typename T>
struct is_custom_free
{
    template <typename U>
    static std::true_type has_free(int (*)[sizeof(std::declval<U>().free(), 0)])
    {
        return {};
    }

    template <typename U>
    static std::false_type has_free(...)
    {
        return {};
    }

    static const bool value = decltype(has_free<T>(NULL))::value;
};
```

這邊其實也是用了 `sizeof` 一個標準的小技巧 `sizeof(std::declval<U>().free(), 0)`，對於 sizeof 括號內逗點前的 expression 編譯器會嘗試估值，但會將其結果捨棄。如果估值失敗了，也就是這個 expression 並不成立，那編譯器就會嘗試其他的 signature，也就是優先度最低的 ellipsis parameter 版本。而且透過 overloading 的機制，也能做到不光是 true or false 的判斷機制。

不過除非工作環境需要，還是使用新的標準來進行開發會更有效率。
