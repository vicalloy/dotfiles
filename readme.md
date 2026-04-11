# dotfiles

## Linux

```bash
sudo apt install wl-clipboard

vim.keymap.set('v', '<D-c>', '"+y')      -- Super+C 复制到系统剪切板
vim.keymap.set('n', '<D-v>', '"+p')      -- Super+V 粘贴
vim.keymap.set('i', '<D-v>', '<C-r>+')
vim.keymap.set('n', '<D-x>', '"+dd')     -- Super+X 剪切
vim.keymap.set('v', '<D-x>', '"+d')
```

## Common

```bash
# 开启代理
proxy_on() {
    export http_proxy="http://192.168.1.1:1080"
    export https_proxy="http://192.168.1.1:1080"
    export all_proxy="socks5://192.168.1.1:1080"
    export no_proxy="localhost,127.0.0.1,::1"
    echo "代理已开启: http://192.168.1.1:1080"
}

# 关闭代理
proxy_off() {
    unset http_proxy
    unset https_proxy
    unset all_proxy
    echo "代理已关闭"
}
```
