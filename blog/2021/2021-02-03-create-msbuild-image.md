在開始學習Docker後我不禁萌生這樣的想法「是否能將建置環境容器化」。傳統進行開發工程師無庸置疑地會安裝能夠成功建置專案的作業環境，然而隨著專案複雜度、專案數量日益增長，作業環境不免顯得雜亂且複雜，更甚者可能出現衝突或空間浪費。

另一個被隱藏的成本是，進行CI/CD的建置伺服器環境也必須部屬相同的環境，如此一來維護成本除了工程師各自的主機還得加上組織建置伺服器的維護成本，傳統人工設定或將整個系統以映像檔安裝的形式難以達到快速、自動的管理，也無法運用既有的CVS體制。

將建置環境視為服務本體並將其容器化行之有年，不少大型企業也同樣這麼做。「譬如平地，雖覆一簣，進」我將目標放在如何將 Visual Studio 2019 的建置環境容器化。以下這個 Dockerfile 是由 Microsoft 2020年初針對 Azure 建置環境虛擬化的[文章](https://docs.microsoft.com/zh-tw/visualstudio/install/build-tools-container?view=vs-2019)參考修改而成。

```docker
# escape=`

# Use the latest Windows Server Core image with .NET Framework 4.8.
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Download the Build Tools bootstrapper.
ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe

RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\BuildTools `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.VC.CMake.Project `
    --add Microsoft.VisualStudio.Component.VC.ATLMFC `
    --add Microsoft.VisualStudio.Component.Windows10SDK.18362 `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
```

主要的差異在於對 Visual Studio Installer 所下的參數將決定要在環境中安裝哪些 Component，有興趣針對自己建置環境調整 Component 的人只要參考[官方清單](https://docs.microsoft.com/zh-tw/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2019)就可以，挑選的方式建議以 Workload 為主，由於 Workload 會直接將標示為 Required 的 Component 加入安裝列表，只要再根據自己的專案性質補足需要的工具就好。

微軟也特別提醒建立 image 時建議使用 2GB 的記憶體容量，避免某些 Workload 的安裝流程使用太多記憶體。

```shell
docker build -t <TAG> -m 2GB .
```

而另一個容易忽略且必要的步驟是：**確認你的 Docker 是採用 Windows containers**，如果不是的話，光是在 `FROM mcr.microsoft.com/dotnet/framework/sdk` 這個 layer 就會出錯。具體的做法是透過 tray 對 Docker 右鍵選單選擇 `Switch to Windows containers...` 或者是透過 CLI 在 Linux container 與 Windows container 間切換：

```shell
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon .
```

一旦我們完成 Image 的建置後就會獲得一個超大容量的 image。啟動容器時再將專案所在路徑 `<PATH>` 掛載到 Container 中 C 槽的目錄 `<FOLDER>`，由於 image 設定的 `ENTRYPOINT` 能讓我們直接進入 Developer Command Prompt，此時已經透過 `VsDevCmd.bat` 設定完相應的環境變數了。

```shell
docker run -v "<PATH>:C:\<FOLDER>" -it <TAG>
```

> 由於 Windows 的檔案系統邏輯與 Linux 不同，只能掛載在 container 中已經存在的 drive；在這個案例中此 image 已經存在的是 C drive。

接著就能順利執行 MSBuild：

```shell
MSBuild <PROJECT> -t:Build -p:Configuration=Release
```

建置完成後應該就能在專案指定的輸出目錄得到執行檔。
