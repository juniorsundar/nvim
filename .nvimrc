version 6.0
let s:cpo_save=&cpo
set cpo&vim
inoremap <C-G>S <Plug>(nvim-surround-insert-line)
inoremap <C-G>s <Plug>(nvim-surround-insert)
inoremap <C-W> u
inoremap <C-U> u
nnoremap  <Cmd>nohlsearch|diffupdate|normal! 
nmap  d
tnoremap  
nnoremap <silent>  G <Nop>
nnoremap <silent>  LW <Nop>
nnoremap <silent>  LD <Nop>
nnoremap <silent>  L <Nop>
nnoremap  FPo <Cmd>Refer Projectile Open
nnoremap  FPs <Cmd>Refer Projectile Switch
nnoremap  F<C-F> <Cmd>Refer Extras FindFile
nnoremap  F <Cmd>Refer Extras FindFile
vnoremap <silent>  F <Nop>
nnoremap <silent>  F <Nop>
nnoremap  c <Cmd>Cling
xnoremap  A <Nop>
nnoremap  A <Nop>
nnoremap  q <Nop>
nnoremap <silent>  P <Nop>
vnoremap  T <Nop>
nnoremap  T <Nop>
vnoremap <silent>   T <Nop>
nnoremap <silent>   T <Nop>
nnoremap <silent>  e <Cmd>Explore
vnoremap <silent>    <Nop>
nnoremap <silent>    <Nop>
vnoremap <silent>   <Nop>
nnoremap <silent>   <Nop>
omap <silent> % <Plug>(MatchitOperationForward)
xmap <silent> % <Plug>(MatchitVisualForward)
nmap <silent> % <Plug>(MatchitNormalForward)
nnoremap & :&&
vnoremap <silent> < <gv
vnoremap <silent> > >gv
xnoremap <silent> <expr> @ mode() ==# 'V' ? ':normal! @'.getcharstr().'' : '@'
xnoremap <silent> <expr> Q mode() ==# 'V' ? ':normal! @=reg_recorded()' : 'Q'
xnoremap S <Plug>(nvim-surround-visual)
nnoremap Y y$
omap <silent> [% <Plug>(MatchitOperationMultiBackward)
xmap <silent> [% <Plug>(MatchitVisualMultiBackward)
nmap <silent> [% <Plug>(MatchitNormalMultiBackward)
omap <silent> ]% <Plug>(MatchitOperationMultiForward)
xmap <silent> ]% <Plug>(MatchitVisualMultiForward)
nmap <silent> ]% <Plug>(MatchitNormalMultiForward)
xmap a% <Plug>(MatchitVisualTextObject)
nnoremap cS <Plug>(nvim-surround-change-line)
nnoremap cs <Plug>(nvim-surround-change)
nnoremap ds <Plug>(nvim-surround-delete)
omap <silent> g% <Plug>(MatchitOperationBackward)
xmap <silent> g% <Plug>(MatchitVisualBackward)
nmap <silent> g% <Plug>(MatchitNormalBackward)
xnoremap gS <Plug>(nvim-surround-visual-line)
nnoremap ySS <Plug>(nvim-surround-normal-cur-line)
nnoremap yS <Plug>(nvim-surround-normal-line)
nnoremap yss <Plug>(nvim-surround-normal-cur)
nnoremap ys <Plug>(nvim-surround-normal)
nnoremap <silent> <S-Up> <Cmd>lua MiniMove.move_line('up')
nnoremap <silent> <S-Down> <Cmd>lua MiniMove.move_line('down')
nnoremap <silent> <S-Right> <Cmd>lua MiniMove.move_line('right')
nnoremap <silent> <S-Left> <Cmd>lua MiniMove.move_line('left')
xnoremap <silent> <S-Up> <Cmd>lua MiniMove.move_selection('up')
xnoremap <silent> <S-Down> <Cmd>lua MiniMove.move_selection('down')
xnoremap <silent> <S-Right> <Cmd>lua MiniMove.move_selection('right')
xnoremap <silent> <S-Left> <Cmd>lua MiniMove.move_selection('left')
xmap <silent> <Plug>(MatchitVisualTextObject) <Plug>(MatchitVisualMultiBackward)o<Plug>(MatchitVisualMultiForward)
onoremap <silent> <Plug>(MatchitOperationMultiForward) :call matchit#MultiMatch("W",  "o")
onoremap <silent> <Plug>(MatchitOperationMultiBackward) :call matchit#MultiMatch("bW", "o")
xnoremap <silent> <Plug>(MatchitVisualMultiForward) :call matchit#MultiMatch("W",  "n")m'gv``
xnoremap <silent> <Plug>(MatchitVisualMultiBackward) :call matchit#MultiMatch("bW", "n")m'gv``
nnoremap <silent> <Plug>(MatchitNormalMultiForward) :call matchit#MultiMatch("W",  "n")
nnoremap <silent> <Plug>(MatchitNormalMultiBackward) :call matchit#MultiMatch("bW", "n")
onoremap <silent> <Plug>(MatchitOperationBackward) :call matchit#Match_wrapper('',0,'o')
onoremap <silent> <Plug>(MatchitOperationForward) :call matchit#Match_wrapper('',1,'o')
xnoremap <silent> <Plug>(MatchitVisualBackward) :call matchit#Match_wrapper('',0,'v')m'gv``
xnoremap <silent> <Plug>(MatchitVisualForward) :call matchit#Match_wrapper('',1,'v'):if col("''") != col("$") | exe ":normal! m'" | endifgv``
nnoremap <silent> <Plug>(MatchitNormalBackward) :call matchit#Match_wrapper('',0,'n')
nnoremap <silent> <Plug>(MatchitNormalForward) :call matchit#Match_wrapper('',1,'n')
tnoremap <C-Bslash><C-Bslash> 
nnoremap <silent> <C-Down> gj
nnoremap <silent> <C-Up> gk
nnoremap <silent> <C-Left> b
nnoremap <silent> <C-Right> w
nnoremap <silent> <M-C-Right> :vertical resize +2
nnoremap <silent> <M-C-Left> :vertical resize -2
nnoremap <silent> <M-C-Down> :resize +2
nnoremap <silent> <M-C-Up> :resize -2
nmap <C-W><C-D> d
nnoremap <C-L> <Cmd>nohlsearch|diffupdate|normal! 
inoremap S <Plug>(nvim-surround-insert-line)
inoremap s <Plug>(nvim-surround-insert)
inoremap  u
inoremap  u
let &cpo=s:cpo_save
unlet s:cpo_save
set clipboard=unnamedplus
set completeopt=menu,menuone,noselect
set expandtab
set fillchars=eob:\ 
set grepformat=%f:%l:%c:%m
set grepprg=rg\ --vimgrep
set helplang=en
set nohlsearch
set ignorecase
set inccommand=split
set mouse=a
set quickfixtextfunc={info\ ->\ v:lua._G.qftf(info)}
set runtimepath=
set runtimepath+=~/.local/share/nvim/site
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/nvim-lint
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/sidekick.nvim
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/persistence.nvim
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/nvim-bqf
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/gitsigns.nvim
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/conform.nvim
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/mini.move
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/flash.nvim
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/nvim-surround
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/nvim-web-devicons
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/which-key.nvim
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/blink.cmp
set runtimepath+=~/.config/nvim/lua/custom/micro.nvim
set runtimepath+=~/.config/nvim/lua/custom/buffers.nvim
set runtimepath+=~/.config/nvim/lua/custom/cling.nvim
set runtimepath+=~/.config/nvim/lua/custom/refer-projectile.nvim
set runtimepath+=~/.config/nvim/lua/custom/refer.nvim
set runtimepath+=~/.config/nvim
set runtimepath+=~/.config/kdedefaults/nvim
set runtimepath+=/nix/store/xqvf655d3brlxm2jw9jpc3nd8gi6pl44-plasma-workspace-6.6.4/etc/xdg/nvim
set runtimepath+=/nix/store/q9gr6qd554bhfq20rql45c706dmkbla1-kglobalacceld-6.6.4/etc/xdg/nvim
set runtimepath+=/nix/store/ljkzqlp40ga335xafy1h3wr4s07ykn91-baloo-6.24.0/etc/xdg/nvim
set runtimepath+=/etc/xdg/nvim
set runtimepath+=~/.local/share/flatpak/exports/etc/xdg/nvim
set runtimepath+=/var/lib/flatpak/exports/etc/xdg/nvim
set runtimepath+=~/.nix-profile/etc/xdg/nvim
set runtimepath+=/nix/profile/etc/xdg/nvim
set runtimepath+=~/.local/state/nix/profile/etc/xdg/nvim
set runtimepath+=/etc/profiles/per-user/juniorsundar/etc/xdg/nvim
set runtimepath+=/nix/var/nix/profiles/default/etc/xdg/nvim
set runtimepath+=/run/current-system/sw/etc/xdg/nvim
set runtimepath+=~/.local/share/nvim/site
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/nvim-treesitter
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/doom-one.nvim
set runtimepath+=/nix/store/y6ybp4vgm2y18fh08dfinq4y2ia5v5cp-uv-0.11.4/share/nvim/site
set runtimepath+=/nix/store/pzdalg368npikvpq4ncz2saxnz19v53k-python3-3.13.12/share/nvim/site
set runtimepath+=/nix/store/r894nhs2rb04dxbfkxazdsg0703075l2-lua-language-server-3.18.0/share/nvim/site
set runtimepath+=/nix/store/vz35rx225imq8rv220a9fm7q29pcz6kq-luajit2.1-luacheck-1.2.0-1/share/nvim/site
set runtimepath+=/nix/store/k8j04scfgc264fdkig9s5r3113s4n9wl-luajit2.1-argparse-0.7.1-1/share/nvim/site
set runtimepath+=/nix/store/zrmg8bj9lxkl7bi19k19jydk73xxk3rs-luajit-2.1.1741730670/share/nvim/site
set runtimepath+=/nix/store/sj3f6y3j8m1831l0gqm1bsk1f46jzkfd-patchelf-0.15.2/share/nvim/site
set runtimepath+=/nix/store/ln9i1hs8v6rv57mzhgmm7d9pq7b5m6bf-ghostty-1.3.1/share/nvim/site
set runtimepath+=/nix/store/xsfc5fcy12nmcdsdwm3dx1xfffh7xv30-gsettings-desktop-schemas-49.1/share/gsettings-schemas/gsettings-desktop-schemas-49.1/nvim/site
set runtimepath+=/nix/store/hjp25ksf3axb4czp7sllvzl1bkpfwsyg-gtk4-4.20.3/share/gsettings-schemas/gtk4-4.20.3/nvim/site
set runtimepath+=/nix/store/xqvf655d3brlxm2jw9jpc3nd8gi6pl44-plasma-workspace-6.6.4/share/nvim/site
set runtimepath+=/nix/store/kandxl389vhs4yk72gcyyxh8vcsn8a65-hunspell-1.7.2/share/nvim/site
set runtimepath+=/nix/store/n5as6kzwm42rl4wdcybm0hkl3rzj4kw7-plasma5support-6.6.4/share/nvim/site
set runtimepath+=/nix/store/aixx182m5bcg9n3w30h26pkkdbjzrzaf-networkmanager-1.56.0/share/nvim/site
set runtimepath+=/nix/store/cij2dqjwb8blvzb5ybggw18x6r6mxfyp-gnutls-3.8.12/share/nvim/site
set runtimepath+=/nix/store/s067sbk2zr0230c1v9dwbn8c8vp5x692-kunitconversion-6.24.0/share/nvim/site
set runtimepath+=/nix/store/ff1qswyiapkyvn7pidplgkpdiv3fxbk3-plasma-nano-6.6.4/share/nvim/site
set runtimepath+=/nix/store/0qfb1dpnh3b31c37ji35dpylj4i5fh96-phonon-4.12.0/share/nvim/site
set runtimepath+=/nix/store/i3mf6zax8kckwlfd5i402djyz1xqqf1v-milou-6.6.4/share/nvim/site
set runtimepath+=/nix/store/l316m6k1wqzgqbsc919pipc9ydvsc4pq-libksysguard-6.6.4/share/nvim/site
set runtimepath+=/nix/store/a9z355222r5rkvy31r3dh6ivi5xz4q74-kwin-6.6.4/share/nvim/site
set runtimepath+=/nix/store/c4z30mvkxi4q0bim4hka829pa63idy6j-kpipewire-6.6.4/share/nvim/site
set runtimepath+=/nix/store/7b9k7v9pbi2rc323fiw8fn3zbh0dacvs-breeze-6.6.4/share/nvim/site
set runtimepath+=/nix/store/p5qbaibbj10ja63607lgx483fr6v7v22-frameworkintegration-6.24.0/share/nvim/site
set runtimepath+=/nix/store/aifsv6hfls6mq8dxpnb0jq03vcgfsqpa-oxygen-icons-6.1.0/share/nvim/site
set runtimepath+=/nix/store/a7n9p3ghiv00cikvcmg6j03rg2cnppgr-aurorae-6.6.4/share/nvim/site
set runtimepath+=/nix/store/0abjprrzmmrljibpb90a3wjk9k4a054m-kdecoration-6.6.4/share/nvim/site
set runtimepath+=/nix/store/q689rsjnk3ww7zhl2dv7j0vmnwbknniq-kuserfeedback-6.24.0/share/nvim/site
set runtimepath+=/nix/store/4mnqm9kx0cd9iv5rl02bm8qvx1686y8k-ktexteditor-6.24.0/share/nvim/site
set runtimepath+=/nix/store/62g8gvfwqi0jkf21iblfcr6dzcpipc5z-kstatusnotifieritem-6.24.0/share/nvim/site
set runtimepath+=/nix/store/6nm2b8qa5ng34njpxdqxs566f9wy9rwg-kscreenlocker-6.6.4/share/nvim/site
set runtimepath+=/nix/store/8bgm7rjb9arbg1zlkyh7pbi36qqar9c1-libplasma-6.6.4/share/nvim/site
set runtimepath+=/nix/store/fyajsk07dmgbdavc2d07wg7p0rwgjpiq-libkscreen-6.6.4/share/nvim/site
set runtimepath+=/nix/store/rzls9s8a48b708cs9i5brj68r70f5y5w-kparts-6.24.0/share/nvim/site
set runtimepath+=/nix/store/zsd0z6fvrwxhjl5637h5x3jhx3j147ms-knotifyconfig-6.24.0/share/nvim/site
set runtimepath+=/nix/store/lgrpsqplqigr4xj8gk0f8zhpmgqxv42z-knewstuff-6.24.0/share/nvim/site
set runtimepath+=/nix/store/6dxci2jd9z7hzf230yvkpxnma6d4xind-kpackage-6.24.0/share/nvim/site
set runtimepath+=/nix/store/57702cizfwamglq28hq5yp2r74krxawy-kirigami-addons-1.12.0/share/nvim/site
set runtimepath+=/nix/store/rib030fis6j73azn4949a60n6gz042sg-gst-plugins-good-1.26.5/share/nvim/site
set runtimepath+=/nix/store/zyh3vyl2k8j9x1wbw02zk1glp5d5i963-gst-plugins-base-1.26.5/share/nvim/site
set runtimepath+=/nix/store/v5qy1399hlrnk8z6mhlzg5jz08rw3l0j-gst-plugins-bad-1.26.5/share/nvim/site
set runtimepath+=/nix/store/s8w14kgj50iqw1w0jdwn9s1m0k4plzgs-gstreamer-1.26.5/share/nvim/site
set runtimepath+=/nix/store/mas1sw41l9ndpfzaiyhgbil4bv4ph3yv-kio-extras-25.12.3/share/nvim/site
set runtimepath+=/nix/store/gbkv334019n1zmbk7kv37wcwd1f1rcrf-syntax-highlighting-6.24.0/share/nvim/site
set runtimepath+=/nix/store/i1z0nbkqbayprv3zp0j4szs54cbf8yzs-kdnssd-6.24.0/share/nvim/site
set runtimepath+=/nix/store/rqcpk1qm8by4sgayxgwgq9sp5rhjbay6-kholidays-6.24.0/share/nvim/site
set runtimepath+=/nix/store/g500lp9fvaahrn92qg827fd14z5a4ygf-kdeclarative-6.24.0/share/nvim/site
set runtimepath+=/nix/store/b1firifcqvfb1iz4a80pwv205ibrhsmp-kcmutils-6.24.0/share/nvim/site
set runtimepath+=/nix/store/0f1p8g6phi78gkccq03119c4a0zmrb0w-kactivitymanagerd-6.6.4/share/nvim/site
set runtimepath+=/nix/store/n7ni2i2wlmrzdzyxnpn8032dg8nhfjx3-kxmlgui-6.24.0/share/nvim/site
set runtimepath+=/nix/store/hgl3956pb39fgjqjy3hhsgkcpws45857-ktextwidgets-6.24.0/share/nvim/site
set runtimepath+=/nix/store/3vap0wnizidzvqlg77w2qgf3mnmq53rp-kglobalaccel-6.24.0/share/nvim/site
set runtimepath+=/nix/store/gd1zk13pzcnwr1s172k5yvrgn2c1394p-kconfigwidgets-6.24.0/share/nvim/site
set runtimepath+=/nix/store/1bkw0xlifkm6dgw77fxmv7sr4qad3r0j-kauth-6.24.0/share/nvim/site
set runtimepath+=/nix/store/ljkzqlp40ga335xafy1h3wr4s07ykn91-baloo-6.24.0/share/nvim/site
set runtimepath+=/nix/store/fsp0vf0vjm1334rkdcyvsm3fkpxv607h-kio-6.24.0/share/nvim/site
set runtimepath+=/nix/store/fs9r9ndnqg7m0mm4aglfii6cykhz082b-solid-6.24.0/share/nvim/site
set runtimepath+=/nix/store/iw6ydv2623pqsygc1y5pckss4lw9jjdj-kwallet-6.24.0/share/nvim/site
set runtimepath+=/nix/store/qqwm9mi346k1qhmhg1aczbag3pxjzhyi-kwindowsystem-6.24.0/share/nvim/site
set runtimepath+=/nix/store/0gi38f6hnlzln7nsj9hxy2561qvna6ls-kservice-6.24.0/share/nvim/site
set runtimepath+=/nix/store/ac56qrsmi5jzbwgla03afd38qric00gv-kjobwidgets-6.24.0/share/nvim/site
set runtimepath+=/nix/store/1f04chj1xiiki4f0cxcnxdz2yrirs9s8-knotifications-6.24.0/share/nvim/site
set runtimepath+=/nix/store/mjylwbkyv4b3jmwsac2gam6283d2ssq5-kitemviews-6.24.0/share/nvim/site
set runtimepath+=/nix/store/mi9m7anm0x51n2bv5lzdvd6iry25skmr-kdoctools-6.24.0/share/nvim/site
set runtimepath+=/nix/store/wyzzghjww2wnhww0rgv5q0dj0ifzgpp1-kcompletion-6.24.0/share/nvim/site
set runtimepath+=/nix/store/nviwz1d5x06f4fpm69g2kd8fv68hm90z-kbookmarks-6.24.0/share/nvim/site
set runtimepath+=/nix/store/06193x4gnhgrbhf7fh1wfj2qp6ss4112-kfilemetadata-6.24.0/share/nvim/site
set runtimepath+=/nix/store/1ga782ml07vy0h503ac4cin0h8d7q6yh-libidn2-2.3.8/share/nvim/site
set runtimepath+=/nix/store/8jznwas4525hpia5z2xx5hm7qwq3n9qn-kdbusaddons-6.24.0/share/nvim/site
set runtimepath+=/nix/store/jsvghh31gnbicbllmpdczjldgkpwjd8r-kcoreaddons-6.24.0/share/nvim/site
set runtimepath+=/nix/store/8vimy52pgiyb164ch2k24vqa7xbr561c-appstream-qt-1.1.2/share/nvim/site
set runtimepath+=/nix/store/nn129jwsznqv7k888wb05m5whpyndqrf-pipewire-1.6.2/share/nvim/site
set runtimepath+=/nix/store/p236967hj8zwfqphwcl815gqaplb71d2-libqalculate-5.10.0/share/nvim/site
set runtimepath+=/nix/store/7b77nr9q19z7hmp2450vh0gyaw3iliwg-qqc2-desktop-style-6.24.0/share/nvim/site
set runtimepath+=/nix/store/iwk926y2chdpma406rinr0v90xd7da90-sonnet-6.24.0/share/nvim/site
set runtimepath+=/nix/store/phhpshxc0kr3q5lq6hjl1awlc1j37izm-kirigami-6.24.0/share/nvim/site
set runtimepath+=/nix/store/k1a3vfqcdd03pnzyi8z2xph3zjqdyh3d-kiconthemes-6.24.0/share/nvim/site
set runtimepath+=/nix/store/s38zz1avnkcwylqb69cwbpb8bzk70nld-kwidgetsaddons-6.24.0/share/nvim/site
set runtimepath+=/nix/store/gfnmlldpnya060gfra68a70na1k4z7mz-karchive-6.24.0/share/nvim/site
set runtimepath+=/nix/store/d5n3cvbinr3r73jkdqrs6f9j8h3sgr0z-breeze-icons-6.24.0/share/nvim/site
set runtimepath+=/nix/store/vq5di1m3i50h5qi2hy9isr486jrl81vy-kcolorscheme-6.24.0/share/nvim/site
set runtimepath+=/nix/store/0q17g0kkjbbfln6xc2zhyxnw1n0skql9-ki18n-6.24.0/share/nvim/site
set runtimepath+=/nix/store/fjxpsqca273h1y9dlrh5slip6saawlhy-kconfig-6.24.0/share/nvim/site
set runtimepath+=/nix/store/nl53wi0m3xcysjhdwj4pll4c241hr8pd-kcodecs-6.24.0/share/nvim/site
set runtimepath+=/nix/store/ca9p0l36x7zw9742ak8vy70phmsng1ns-cups-2.4.16/share/nvim/site
set runtimepath+=/nix/store/qk1d0xniardydr9rkhnnivz2ccmznw2q-cups-2.4.16-lib/share/nvim/site
set runtimepath+=/nix/store/a8lqn6cgwpab63c14xff3cqp8zfrvna4-fontconfig-2.17.1-lib/share/nvim/site
set runtimepath+=/nix/store/h0yawqdl8qh1bq6rmwbwqcm3qf1l29ii-util-linux-2.41.3-lib/share/nvim/site
set runtimepath+=/nix/store/ik8a7b32nqv2q5p4g86hmp65jklmrp3g-systemd-259.3/share/nvim/site
set runtimepath+=/nix/store/d864rlg855kf2hnnnfdzcx54grp8n10x-glib-2.86.3/share/nvim/site
set runtimepath+=/nix/store/kfci1gnn12ip5xy492m0hd10hmgyxr6x-gettext-0.26/share/nvim/site
set runtimepath+=/nix/store/bh181pfpx0974lrw1x0dsidxlsiwxgc5-desktops/share/nvim/site
set runtimepath+=~/.local/share/flatpak/exports/share/nvim/site
set runtimepath+=/var/lib/flatpak/exports/share/nvim/site
set runtimepath+=~/.nix-profile/share/nvim/site
set runtimepath+=/nix/profile/share/nvim/site
set runtimepath+=~/.local/state/nix/profile/share/nvim/site
set runtimepath+=/etc/profiles/per-user/juniorsundar/share/nvim/site
set runtimepath+=/nix/var/nix/profiles/default/share/nvim/site
set runtimepath+=/run/current-system/sw/share/nvim/site
set runtimepath+=/nix/store/p3cpz8p3ykz8q8mmp4rpa5mzw6gkkp13-neovim-unwrapped-0.12.1/share/nvim/runtime
set runtimepath+=/nix/store/p3cpz8p3ykz8q8mmp4rpa5mzw6gkkp13-neovim-unwrapped-0.12.1/share/nvim/runtime/pack/dist/opt/netrw
set runtimepath+=/nix/store/p3cpz8p3ykz8q8mmp4rpa5mzw6gkkp13-neovim-unwrapped-0.12.1/share/nvim/runtime/pack/dist/opt/matchit
set runtimepath+=/nix/store/p3cpz8p3ykz8q8mmp4rpa5mzw6gkkp13-neovim-unwrapped-0.12.1/share/nvim/runtime/pack/dist/opt/nvim.undotree
set runtimepath+=/nix/store/p3cpz8p3ykz8q8mmp4rpa5mzw6gkkp13-neovim-unwrapped-0.12.1/share/nvim/runtime/pack/dist/opt/nvim.difftool
set runtimepath+=/nix/store/p3cpz8p3ykz8q8mmp4rpa5mzw6gkkp13-neovim-unwrapped-0.12.1/lib/nvim
set runtimepath+=~/.local/share/nvim/site/pack/core/opt/nvim-bqf/after
set runtimepath+=/run/current-system/sw/share/nvim/site/after
set runtimepath+=/nix/var/nix/profiles/default/share/nvim/site/after
set runtimepath+=/etc/profiles/per-user/juniorsundar/share/nvim/site/after
set runtimepath+=~/.local/state/nix/profile/share/nvim/site/after
set runtimepath+=/nix/profile/share/nvim/site/after
set runtimepath+=~/.nix-profile/share/nvim/site/after
set runtimepath+=/var/lib/flatpak/exports/share/nvim/site/after
set runtimepath+=~/.local/share/flatpak/exports/share/nvim/site/after
set runtimepath+=/nix/store/bh181pfpx0974lrw1x0dsidxlsiwxgc5-desktops/share/nvim/site/after
set runtimepath+=/nix/store/kfci1gnn12ip5xy492m0hd10hmgyxr6x-gettext-0.26/share/nvim/site/after
set runtimepath+=/nix/store/d864rlg855kf2hnnnfdzcx54grp8n10x-glib-2.86.3/share/nvim/site/after
set runtimepath+=/nix/store/ik8a7b32nqv2q5p4g86hmp65jklmrp3g-systemd-259.3/share/nvim/site/after
set runtimepath+=/nix/store/h0yawqdl8qh1bq6rmwbwqcm3qf1l29ii-util-linux-2.41.3-lib/share/nvim/site/after
set runtimepath+=/nix/store/a8lqn6cgwpab63c14xff3cqp8zfrvna4-fontconfig-2.17.1-lib/share/nvim/site/after
set runtimepath+=/nix/store/qk1d0xniardydr9rkhnnivz2ccmznw2q-cups-2.4.16-lib/share/nvim/site/after
set runtimepath+=/nix/store/ca9p0l36x7zw9742ak8vy70phmsng1ns-cups-2.4.16/share/nvim/site/after
set runtimepath+=/nix/store/nl53wi0m3xcysjhdwj4pll4c241hr8pd-kcodecs-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/fjxpsqca273h1y9dlrh5slip6saawlhy-kconfig-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/0q17g0kkjbbfln6xc2zhyxnw1n0skql9-ki18n-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/vq5di1m3i50h5qi2hy9isr486jrl81vy-kcolorscheme-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/d5n3cvbinr3r73jkdqrs6f9j8h3sgr0z-breeze-icons-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/gfnmlldpnya060gfra68a70na1k4z7mz-karchive-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/s38zz1avnkcwylqb69cwbpb8bzk70nld-kwidgetsaddons-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/k1a3vfqcdd03pnzyi8z2xph3zjqdyh3d-kiconthemes-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/phhpshxc0kr3q5lq6hjl1awlc1j37izm-kirigami-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/iwk926y2chdpma406rinr0v90xd7da90-sonnet-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/7b77nr9q19z7hmp2450vh0gyaw3iliwg-qqc2-desktop-style-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/p236967hj8zwfqphwcl815gqaplb71d2-libqalculate-5.10.0/share/nvim/site/after
set runtimepath+=/nix/store/nn129jwsznqv7k888wb05m5whpyndqrf-pipewire-1.6.2/share/nvim/site/after
set runtimepath+=/nix/store/8vimy52pgiyb164ch2k24vqa7xbr561c-appstream-qt-1.1.2/share/nvim/site/after
set runtimepath+=/nix/store/jsvghh31gnbicbllmpdczjldgkpwjd8r-kcoreaddons-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/8jznwas4525hpia5z2xx5hm7qwq3n9qn-kdbusaddons-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/1ga782ml07vy0h503ac4cin0h8d7q6yh-libidn2-2.3.8/share/nvim/site/after
set runtimepath+=/nix/store/06193x4gnhgrbhf7fh1wfj2qp6ss4112-kfilemetadata-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/nviwz1d5x06f4fpm69g2kd8fv68hm90z-kbookmarks-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/wyzzghjww2wnhww0rgv5q0dj0ifzgpp1-kcompletion-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/mi9m7anm0x51n2bv5lzdvd6iry25skmr-kdoctools-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/mjylwbkyv4b3jmwsac2gam6283d2ssq5-kitemviews-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/1f04chj1xiiki4f0cxcnxdz2yrirs9s8-knotifications-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/ac56qrsmi5jzbwgla03afd38qric00gv-kjobwidgets-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/0gi38f6hnlzln7nsj9hxy2561qvna6ls-kservice-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/qqwm9mi346k1qhmhg1aczbag3pxjzhyi-kwindowsystem-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/iw6ydv2623pqsygc1y5pckss4lw9jjdj-kwallet-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/fs9r9ndnqg7m0mm4aglfii6cykhz082b-solid-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/fsp0vf0vjm1334rkdcyvsm3fkpxv607h-kio-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/ljkzqlp40ga335xafy1h3wr4s07ykn91-baloo-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/1bkw0xlifkm6dgw77fxmv7sr4qad3r0j-kauth-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/gd1zk13pzcnwr1s172k5yvrgn2c1394p-kconfigwidgets-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/3vap0wnizidzvqlg77w2qgf3mnmq53rp-kglobalaccel-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/hgl3956pb39fgjqjy3hhsgkcpws45857-ktextwidgets-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/n7ni2i2wlmrzdzyxnpn8032dg8nhfjx3-kxmlgui-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/0f1p8g6phi78gkccq03119c4a0zmrb0w-kactivitymanagerd-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/b1firifcqvfb1iz4a80pwv205ibrhsmp-kcmutils-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/g500lp9fvaahrn92qg827fd14z5a4ygf-kdeclarative-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/rqcpk1qm8by4sgayxgwgq9sp5rhjbay6-kholidays-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/i1z0nbkqbayprv3zp0j4szs54cbf8yzs-kdnssd-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/gbkv334019n1zmbk7kv37wcwd1f1rcrf-syntax-highlighting-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/mas1sw41l9ndpfzaiyhgbil4bv4ph3yv-kio-extras-25.12.3/share/nvim/site/after
set runtimepath+=/nix/store/s8w14kgj50iqw1w0jdwn9s1m0k4plzgs-gstreamer-1.26.5/share/nvim/site/after
set runtimepath+=/nix/store/v5qy1399hlrnk8z6mhlzg5jz08rw3l0j-gst-plugins-bad-1.26.5/share/nvim/site/after
set runtimepath+=/nix/store/zyh3vyl2k8j9x1wbw02zk1glp5d5i963-gst-plugins-base-1.26.5/share/nvim/site/after
set runtimepath+=/nix/store/rib030fis6j73azn4949a60n6gz042sg-gst-plugins-good-1.26.5/share/nvim/site/after
set runtimepath+=/nix/store/57702cizfwamglq28hq5yp2r74krxawy-kirigami-addons-1.12.0/share/nvim/site/after
set runtimepath+=/nix/store/6dxci2jd9z7hzf230yvkpxnma6d4xind-kpackage-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/lgrpsqplqigr4xj8gk0f8zhpmgqxv42z-knewstuff-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/zsd0z6fvrwxhjl5637h5x3jhx3j147ms-knotifyconfig-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/rzls9s8a48b708cs9i5brj68r70f5y5w-kparts-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/fyajsk07dmgbdavc2d07wg7p0rwgjpiq-libkscreen-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/8bgm7rjb9arbg1zlkyh7pbi36qqar9c1-libplasma-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/6nm2b8qa5ng34njpxdqxs566f9wy9rwg-kscreenlocker-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/62g8gvfwqi0jkf21iblfcr6dzcpipc5z-kstatusnotifieritem-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/4mnqm9kx0cd9iv5rl02bm8qvx1686y8k-ktexteditor-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/q689rsjnk3ww7zhl2dv7j0vmnwbknniq-kuserfeedback-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/0abjprrzmmrljibpb90a3wjk9k4a054m-kdecoration-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/a7n9p3ghiv00cikvcmg6j03rg2cnppgr-aurorae-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/aifsv6hfls6mq8dxpnb0jq03vcgfsqpa-oxygen-icons-6.1.0/share/nvim/site/after
set runtimepath+=/nix/store/p5qbaibbj10ja63607lgx483fr6v7v22-frameworkintegration-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/7b9k7v9pbi2rc323fiw8fn3zbh0dacvs-breeze-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/c4z30mvkxi4q0bim4hka829pa63idy6j-kpipewire-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/a9z355222r5rkvy31r3dh6ivi5xz4q74-kwin-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/l316m6k1wqzgqbsc919pipc9ydvsc4pq-libksysguard-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/i3mf6zax8kckwlfd5i402djyz1xqqf1v-milou-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/0qfb1dpnh3b31c37ji35dpylj4i5fh96-phonon-4.12.0/share/nvim/site/after
set runtimepath+=/nix/store/ff1qswyiapkyvn7pidplgkpdiv3fxbk3-plasma-nano-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/s067sbk2zr0230c1v9dwbn8c8vp5x692-kunitconversion-6.24.0/share/nvim/site/after
set runtimepath+=/nix/store/cij2dqjwb8blvzb5ybggw18x6r6mxfyp-gnutls-3.8.12/share/nvim/site/after
set runtimepath+=/nix/store/aixx182m5bcg9n3w30h26pkkdbjzrzaf-networkmanager-1.56.0/share/nvim/site/after
set runtimepath+=/nix/store/n5as6kzwm42rl4wdcybm0hkl3rzj4kw7-plasma5support-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/kandxl389vhs4yk72gcyyxh8vcsn8a65-hunspell-1.7.2/share/nvim/site/after
set runtimepath+=/nix/store/xqvf655d3brlxm2jw9jpc3nd8gi6pl44-plasma-workspace-6.6.4/share/nvim/site/after
set runtimepath+=/nix/store/hjp25ksf3axb4czp7sllvzl1bkpfwsyg-gtk4-4.20.3/share/gsettings-schemas/gtk4-4.20.3/nvim/site/after
set runtimepath+=/nix/store/xsfc5fcy12nmcdsdwm3dx1xfffh7xv30-gsettings-desktop-schemas-49.1/share/gsettings-schemas/gsettings-desktop-schemas-49.1/nvim/site/after
set runtimepath+=/nix/store/ln9i1hs8v6rv57mzhgmm7d9pq7b5m6bf-ghostty-1.3.1/share/nvim/site/after
set runtimepath+=/nix/store/sj3f6y3j8m1831l0gqm1bsk1f46jzkfd-patchelf-0.15.2/share/nvim/site/after
set runtimepath+=/nix/store/zrmg8bj9lxkl7bi19k19jydk73xxk3rs-luajit-2.1.1741730670/share/nvim/site/after
set runtimepath+=/nix/store/k8j04scfgc264fdkig9s5r3113s4n9wl-luajit2.1-argparse-0.7.1-1/share/nvim/site/after
set runtimepath+=/nix/store/vz35rx225imq8rv220a9fm7q29pcz6kq-luajit2.1-luacheck-1.2.0-1/share/nvim/site/after
set runtimepath+=/nix/store/r894nhs2rb04dxbfkxazdsg0703075l2-lua-language-server-3.18.0/share/nvim/site/after
set runtimepath+=/nix/store/pzdalg368npikvpq4ncz2saxnz19v53k-python3-3.13.12/share/nvim/site/after
set runtimepath+=/nix/store/y6ybp4vgm2y18fh08dfinq4y2ia5v5cp-uv-0.11.4/share/nvim/site/after
set runtimepath+=~/.local/share/nvim/site/after
set runtimepath+=/run/current-system/sw/etc/xdg/nvim/after
set runtimepath+=/nix/var/nix/profiles/default/etc/xdg/nvim/after
set runtimepath+=/etc/profiles/per-user/juniorsundar/etc/xdg/nvim/after
set runtimepath+=~/.local/state/nix/profile/etc/xdg/nvim/after
set runtimepath+=/nix/profile/etc/xdg/nvim/after
set runtimepath+=~/.nix-profile/etc/xdg/nvim/after
set runtimepath+=/var/lib/flatpak/exports/etc/xdg/nvim/after
set runtimepath+=~/.local/share/flatpak/exports/etc/xdg/nvim/after
set runtimepath+=/etc/xdg/nvim/after
set runtimepath+=/nix/store/ljkzqlp40ga335xafy1h3wr4s07ykn91-baloo-6.24.0/etc/xdg/nvim/after
set runtimepath+=/nix/store/q9gr6qd554bhfq20rql45c706dmkbla1-kglobalacceld-6.6.4/etc/xdg/nvim/after
set runtimepath+=/nix/store/xqvf655d3brlxm2jw9jpc3nd8gi6pl44-plasma-workspace-6.6.4/etc/xdg/nvim/after
set runtimepath+=~/.config/kdedefaults/nvim/after
set runtimepath+=~/.config/nvim/after
set scrolloff=1
set shiftwidth=4
set noshowmode
set showtabline=0
set smartcase
set softtabstop=4
set splitbelow
set splitright
set statusline=\ 
set tabstop=4
set termguicolors
set timeoutlen=500
set undofile
set updatetime=500
set window=65
" vim: set ft=vim :
