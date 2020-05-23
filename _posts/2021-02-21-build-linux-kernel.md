---
layout: post
title: Linux Kernel 開發環境設定
tags:
  - c
  - linuxkernel
---
最近開始學習在 linux 上進行開發，長期以來也好奇 linux kernel 的開發流程。設置測試環境的流程並不複雜，但也有一些眉角，因此在此以筆記紀錄。首要是建置 Kernel 的必要工具，每個發行版的 package 名稱都不盡相同，ubuntu 有提供現成的[安裝指令](https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel)

```bash
sudo apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf
```

kernel的原始碼則透過 `git clone`，有需要的話再 checkout 特定版號即可。在進行 `menuconfig` 時，要記得將 `CONFIG_DEBUG_INFO` 開啟 `CONFIG_DEBUG_INFO_REDUCED` 關閉。

```bash
git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
make arch=x86_64 menuconfig
make -j8
```

kernel image 會建置在 `arch/x86/boot/bzImage`，在進行開發測試時我們不太可能直接將現有的 kernel 替換成開發中的 kernel，也不會頻繁地在新機器上安裝系統，這裡就要使用到 QEMU。

```bash
sudo apt-get install qemu qemu-system
qemu-system-x86_64 -kernel bzImage -append "console=ttyS0 nokaslr" -m 512M -serial stdio -display none -s
```

起動 QEMU 測試核心後會發現 kernel 進入 panic，因為光有核心我們還缺乏核心掛載的檔案系統。這時我們要採用 2.6 以後引入的 initramfs 製作一塊會在 ram 空間展開映像檔。我們還需要一套方便操作系統的指令程式集，在此選用 busybox，並將其編譯為monolithic(`Build BusyBox as a static binary` 選項要開啟)。

```bash
git clone git://busybox.net/busybox.git
cd busybox
make menuconfig #[*] Build BusyBox as a static binary
make
```

建置完成後我們會取得 busybox 的可執行二進位檔。接著要製作 rootfs 的空間。

```bash
mkdir -p initramfs/{bin,sbin,etc,proc,sys}
cd initramfs
cp path/to/busybox bin/
ln -s bin/busybox bin/sh
vim init
chmod +x init
find . | cpio -H newc -o > ../initramfs.cpio
```

init 腳本內容為下：

```bash
#!/bin/sh
/bin/busybox --install -s /bin
mount -t proc proc /proc
mount -t sysfs sysfs /sys

exec /bin/sh
```

我們在此只求一個可以暫時測試 kernel 的系統環境，因此腳本停留在 kernel 初始化系統的階段。接著我們再次啟動模擬器就能把玩系統。

```bash
sudo apt-get install qemu qemu-system
qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio -append "console=ttyS0 nokaslr" -m 512M -serial stdio -display none -s
```

我們還需要對 linux 系統進行除錯，由於 qemu 啟動虛擬機時已經透過 `-s` 替我們開啟 port 1234 作為核心的除錯埠，我們在啟用 gdb 前只要在 `~/.gdbinit` 加上 `add-auto-load-safe-path /path/to/linux` 即可讓 linux 必要的除錯輔助腳本及工具加入 gdb。

```bash
gdb vmlinux
(gdb) target remote :1234
(gdb) lx-symbols
```

如此一來就可進行除錯。
