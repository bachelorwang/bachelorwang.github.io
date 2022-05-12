在我開始撰寫USD一系列的教學文章時其實就已經著手開發[bachelorwang/xpsusd](https://github.com/bachelorwang/xpsusd)，XPS對有在接觸粉絲藝術創作的人應該不陌生，全名是 Xna Posing Studio 前身是 XNALara。由於這是下班閒暇時間寫的，我並沒有打算完全支援所有XPS格式的版本(特別是在XPS沒有公開原始碼的狀況下)。這次的教學是以讀者已經明白[如何建立 USD Stage](2021-02-04-first-usd.md)為前提撰寫的。

```cpp
XpsReader reader;
auto model = reader.readBinaryXps(input_file_path.c_str());
auto root = UsdSkelRoot::Define(
  stage, 
  SdfPath::AbsoluteRootPath().AppendChild(XPS_TOKEN->root)
);
```

首先將 XPS 檔案讀入，這裡的實作細節就不贅述。`UsdSkelRoot::Define` 傳入的引數 `SdfPath::AbsoluteRootPath().AppendChild(XPS_TOKEN->root)` 是一個較為彈性的寫法，`SdfPath::AbsoluteRootPath` 為我們定義了根路徑的字串 `"/"`，`XPS_TOKEN` 則是我透過 `TF_DEFINE_PRIVATE_TOKENS(<TokenSetName>, [<token>])` 所預先定義的寫法，如此大費周章除了減少字串成本外，更重要的是對於路徑組成的程式碼可讀性與可維護性有所提升。當然最重要的問題是：為何要定義 `UsdSkelRoot`？這個 schema 對任何具有 skinning 行為的 prim 都是不可或缺的，考慮到未來我們的終極目標是讓角色動起來，在這邊就先定義 `UsdSkelRoot`。

下一步接著就是將 XPS 內所有的 mesh 都建立在 stage之中，我們進行一個遍歷並定義 `UsdGeomMesh` 物件：

```cpp
for (const auto& xps_mesh : model->meshes) {
    auto name = xps_mesh.name.empty() ? std::to_string((size_t)&xps_mesh)
                                      : xps_mesh.name;
    const auto&& mesh_path = root.GetPath().AppendChild(TfToken(name));
    auto mesh = UsdGeomMesh::Define(stage, mesh_path);
}
```

這裡來到另一個容易失敗的環節，可能不少人閱覽輸出的 `usda` 會發現一個 `Mesh` 也不存在或總數對不上。這並不是程式有錯誤，而是忽略了 USD 的規則。 USD 的路徑節點不得以數字開頭也不允許不合法的字元，雖然說我們可以透過瀏覽官方文件得知完整的路徑規則，但自己轉換仍是一項苦活。所幸 USD 已經提供了這樣的工具：

```cpp
if (!TfIsValidIdentifier(name))
      name = TfMakeValidIdentifier(name);
```

解決路徑問題後我們還得為 mesh 填充內容才行，`UsdGeomMesh` schema 已經定義了必要的 attribute，最低限度只要完成頂點座標與面就能看到 mesh，首先是頂點。

```cpp
VtVec3fArray positions(xps_mesh.vertices.size());
GfRange3f extent;
for (size_t i = 0; i < positions.size(); ++i) {
  positions[i] = xps_mesh.vertices[i].position;
  extent.UnionWith(positions[i]);
}
VtVec3fArray extent_arr({extent.GetMin(), extent.GetMax()});
mesh.CreateExtentAttr().Set(extent_arr);
mesh.CreatePointsAttr().Set(positions);
```

attribute 通常具有兩種介面，以 `points` 為例 `CreatePointsAttr` 與 `GetPointsAttr` 都能達成我們設置 attribute 的手段，但各自用途又有所不同。`Create` 在 USD 定義中是編輯行為，若 attribute 未定義則會定義一個，但在多線程作業中可能會導致衝突；`Get` 則是唯獨的手段，並不保證 attribute 一定存在但保證 thread-safe。`Create` 通常用於改寫、產生場景資料，而 `Get` 用於讀取或匯入。

```cpp
assert(xps_mesh.indices.size() % 3 == 0);
const auto face_count = xps_mesh.indices.size() / 3;
VtIntArray indices(face_count * 3);
VtIntArray face_counts(face_count, 3);
size_t last = 0;
for (size_t f = 0; f < face_count; ++f) {
  const auto count = face_counts[f];
  for (int i = 0; i < count; ++i)
    indices[last + i] = xps_mesh.indices[last + i];
  last += count;
}
mesh.CreateFaceVertexIndicesAttr().Set(indices);
mesh.CreateFaceVertexCountsAttr().Set(face_counts);
```

USD 允許 polygon mesh，但 XPS 只有 triangle mesh 狀況要單純許多；`faceVertexCounts` 屬性是必須的。一旦我們將 mesh 的 attribute 設定完成再儲存 stage 就能得到結果：

![result](/assets/2021-02-04-first-usd-kokoro.PNG)

