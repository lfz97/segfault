#! /bin/bash

# Docker sf-guest setup script (docker build)

CR="\e[1;31m" # red
CN="\e[0m"    # none

WARN()
{
	WARNS+=("$*")
}

# Fatal Error when any of the following commands fail
set -e

# ZSH setup
sed 's/#\(.*\)prompt_symbol=/\1prompt_symbol=/g' -i /etc/skel/.zshrc
sed 's/\(\s*PROMPT=.*\)n└─\(.*\)/\1n%{%G└%}%{%G─%}\2/g' -i /etc/skel/.zshrc
sed '/\^P toggle_oneline_prompt/d' -i /etc/skel/.zshrc
echo '[[ -e /etc/shellrc ]] && source /etc/shellrc' >>/etc/skel/.zshrc

echo '[[ -e /etc/shellrc ]] && source /etc/shellrc' >>/etc/skel/.bashrc
sed 's/\(\s*\)set mouse=/"\1set mouse=/g' -i /usr/share/vim/vim90/defaults.vim
rm -f /etc/skel/.bashrc.original
rm -f /usr/bin/kali-motd /etc/motd
chsh -s /bin/zsh
useradd  -s /bin/zsh user
ln -s openssh /usr/lib/ssh
sed 's/\/root/\/sec\/root/g' -i /etc/passwd
sed 's/\/home\//\/sec\/home\//g' -i /etc/passwd

# Docker depends on /root to exist or otherwise throws a:
# [process_linux.go:545: container init caused: mkdir /root: file exists: unknown]
rm -rf /root /home
mkdir -p /sec/root
ln -s /sec/root /root
ln -s /sec/home /home
cp -a /etc/skel /sec/root

echo "NOT ENCRYPTED" >/sec/THIS-DIRECTORY-IS-NOT-ENCRYPTED--DO-NOT-USE.txt

# Need to set correct permission which may have gotten skewed when building
# docker inside vmbox from shared host drive. On VMBOX share all
# source files and directories are set to "rwxrwx--- root:vobxsf" :/
fixr()
{
	local dir
	dir=$1
	[[ ! -d "$dir" ]] && return

	find "$dir" -type f -exec chmod 644 {} \;
	find "$dir" -type d -exec chmod 755 {} \;
}
ln -sf /sec/usr/etc/rc.local /etc/rc.local
chown root:root /etc /etc/profile.d /etc/profile.d/segfault.sh
chmod 755 /usr /usr/bin /usr/sbin /etc /etc/profile.d
chmod 755 /usr/bin/mosh-server-hook /usr/bin/xpra-hook /usr/bin/brave-browser-stable-hook /usr/bin/xterm-dark /usr/sbin/halt
chmod 644 /etc/profile.d/segfault.sh
chmod 644 /etc/shellrc /etc/zsh_command_not_found /etc/zsh_profile
fixr /usr/share/www
fixr /usr/share/source-highlight
ln -s batcat /usr/bin/bat
ln -s crackmapexec /usr/bin/cme
ln -s /sf/bin/sf-motd.sh /usr/bin/motd
ln -s /sf/bin/sf-motd.sh /usr/bin/help
ln -s /sf/bin/sf-motd.sh /usr/bin/info
rm -f /usr/sbin/shutdown /usr/sbin/reboot
ln -s /usr/sbin/halt /usr/sbin/shutdown
ln -s /usr/sbin/halt /usr/sbin/reboot
ln -s /usr/bin/code /usr/bin/vscode
# No idea why /etc/firefox-esr does not work...
if [[ -e /usr/lib/firefox/defaults/pref/channel-prefs.js ]]; then
	echo 'pref("network.dns.blockDotOnion", false);
pref("browser.tabs.inTitlebar", 1);
pref("browser.shell.checkDefaultBrowser", false);' >>/usr/lib/firefox/defaults/pref/channel-prefs.js
else
	[[ -e /usr/bin/firefox ]] && WARN "Firefox config could not be updated."
fi
ln -s /usr/games/lolcat /usr/bin/lolcat
set +e

# Non-Fatal. WARN but continue if any of the following commands fail
sed 's/^TorAddress.*/TorAddress 172.20.0.111/' -i /etc/tor/torsocks.conf || WARN "Failed /etc/tor/torsocks.conf"

# Move "$1" to "$1".orig and link "$1" -> "$1"-hook
mk_hook()
{
	local fn
	fn="${1}/${2}"
	[[ ! -e "$fn" ]] && return
	( cd "${1}"
	mv "$fn" "${fn}.orig"
	ln -s "${fn}-hook" "$fn" )
}
mk_hook /usr/bin        mosh-server
mk_hook /usr/bin        xpra
mk_hook /usr/bin        brave-browser-stable
mk_hook /usr/bin        chromium
mk_hook /usr/share/code code

# Output warnings and wait (if there are any)
[[ ${#WARNS[@]} -gt 0 ]] && {
	while [[ $i -lt ${#WARNS[@]} ]]; do
		((i++))
		echo -e "[${CR}WARN #$i${CN}] ${WARNS[$((i-1))]}"
	done
	echo "Continuing in 5 seconds..."
	sleep 5
}

exit 0
