#!/bin/bash
svn_export() {
	# 参数1是分支名, 参数2是子目录, 参数3是目标目录, 参数4仓库地址
	TMP_DIR="$(mktemp -d)" || exit 1
 	ORI_DIR="$PWD"
	[ -d "$3" ] || mkdir -p "$3"
	TGT_DIR="$(cd "$3"; pwd)"
	git clone --depth 1 -b "$1" "$4" "$TMP_DIR" >/dev/null 2>&1 && \
	cd "$TMP_DIR/$2" && rm -rf .git >/dev/null 2>&1 && \
	cp -af . "$TGT_DIR/" && cd "$ORI_DIR"
	rm -rf "$TMP_DIR"
}
#cp -f $GITHUB_WORKSPACE/patch/mt7621_xiaomi_mi-router-3g.dts target/linux/ramips/dts/mt7621_xiaomi_mi-router-3g.dts
#cp -f $GITHUB_WORKSPACE/patch/02_network target/linux/ramips/mt7621/base-files/etc/board.d/02_network
cp -f $GITHUB_WORKSPACE/patch/102-mt7621-fix-cpu-clk-add-clkdev.patch target/linux/ramips/patches-5.4/102-mt7621-fix-cpu-clk-add-clkdev.patch
cp -f $GITHUB_WORKSPACE/patch/322-mt7621-fix-cpu-clk-add-clkdev.patch target/linux/ramips/patches-5.10/322-mt7621-fix-cpu-clk-add-clkdev.patch

# 删除冲突软件和依赖
rm -rf feeds/packages/lang/golang 
rm -rf feeds/luci/applications/luci-app-pushbot
rm -rf feeds/luci/applications/luci-app-serverchan
rm -rf feeds/luci/applications/luci-app-adguardhome
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-zerotier
rm -rf feeds/packages/net/zerotier
rm -rf feeds/packages/net/smartdns
find ./ | grep Makefile | grep v2ray-geodata | xargs rm -f
#git clone --depth 1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang
# 下载插件
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth 1 https://github.com/chenmozhijin/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth 1 https://github.com/OldCoding/luci-app-filebrowser package/luci-app-filebrowser
svn_export "main" "general/golang" "feeds/packages/lang/golang" "https://github.com/breakings/OpenWrt"
svn_export "master" "applications/luci-app-zerotier" "feeds/luci/applications/luci-app-zerotier" "https://github.com/immortalwrt/luci"
svn_export "master" "net/zerotier" "feeds/packages/net/zerotier" "https://github.com/immortalwrt/packages"

# 编译 po2lmo (如果有po2lmo可跳过)
#pushd package/luci-app-openclash/tools/po2lmo
#make && sudo make install
#popd

# 安装插件
./scripts/feeds update -i
./scripts/feeds install -a
set -x
# 个性化设置
cd package
sed -i "s/OpenWrt /Wing build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" lean/default-settings/files/zzz-default-settings
sed -i "s/OpenWrt/MI-R3G/" base-files/files/bin/config_generate
sed -i "/firewall\.user/d" lean/default-settings/files/zzz-default-settings
sed -i "/openwrt_luci/d" lean/default-settings/files/zzz-default-settings

#AdguardHome
cd ./luci-app-adguardhome/root/usr
mkdir -p ./bin/AdGuardHome && cd ./bin/AdGuardHome
ADG_VER=$(curl -sfL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases 2>/dev/null | grep 'tag_name' | egrep -o "v[0-9].+[0-9.]" | awk 'NR==1')
curl -sfL -o /tmp/AdGuardHome_linux.tar.gz https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADG_VER}/AdGuardHome_linux_mipsle_softfloat.tar.gz
tar -zxf /tmp/*.tar.gz -C /tmp/ && chmod +x /tmp/AdGuardHome/AdGuardHome
upx_latest_ver="$(curl -sfL https://api.github.com/repos/upx/upx/releases/latest 2>/dev/null | egrep 'tag_name' | egrep '[0-9.]+' -o 2>/dev/null)"
curl -sfL -o /tmp/upx-${upx_latest_ver}-amd64_linux.tar.xz "https://github.com/upx/upx/releases/download/v${upx_latest_ver}/upx-${upx_latest_ver}-amd64_linux.tar.xz"
xz -d -c /tmp/upx-${upx_latest_ver}-amd64_linux.tar.xz | tar -x -C "/tmp"
/tmp/upx-${upx_latest_ver}-amd64_linux/upx --ultra-brute /tmp/AdGuardHome/AdGuardHome > /dev/null 2>&1
mv /tmp/AdGuardHome/AdGuardHome ./ && rm -rf /tmp/AdGuardHome
#cd $GITHUB_WORKSPACE/openwrt && cd feeds/luci/applications/luci-app-wrtbwmon
#sed -i 's/ selected=\"selected\"//g' ./luasrc/view/wrtbwmon/wrtbwmon.htm && sed -i 's/\"1\"/\"1\" selected=\"selected\"/g' ./luasrc/view/wrtbwmon/wrtbwmon.htm
#sed -i 's/interval: 5/interval: 1/g' ./htdocs/luci-static/wrtbwmon/wrtbwmon.js
