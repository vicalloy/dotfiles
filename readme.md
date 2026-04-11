# dotfiles

## Linux

### neovim

```bash
sudo apt install wl-clipboard
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
