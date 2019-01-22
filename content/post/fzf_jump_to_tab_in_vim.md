+++
date = "2019-01-22T21:01:31+13:00"
title = "Jump to existing tab using fzf in Vim"
categories = ["tech"]
tags = ["vim", "fzf"]
draft = false
description = "Use fzf in vim to quickly jump to specific tab"
+++

[fzf][1] is a powerful console tool which can help you a lot during daily
development. And what's really awesome is it's also integated in Vim. 
[fzf.vim][3] provides a set of ready-made commands and [this wiki page][2]
gives basic tutorial about how to write your own fzf function in vimrc and many
useful snippets.

For a long time, I'm looking for a quick way to jump to one tab when opening a
lot tabs in Vim. I thought fzf maybe can do that like it does to open file or
open a buffer. However, I could not find such solution after google. So, I
implemented it as below:


```vim
" Jump to tab: <Leader>t
function tabName(n)
    let buflist = tabpagebuflist(a:n)
    let winnr = tabpagewinnr(a:n)
    return fnamemodify(bufname(buflist[winnr - 1]), ':t')
endfunction

function! s:jumpToTab(line)
    let pair = split(a:line, ' ')
    let cmd = pair[0].'gt'
    execute 'normal' cmd
endfunction

nnoremap <silent> <Leader>t :call fzf#run({
\   'source':  reverse(map(range(1, tabpagenr('$')), 'v:val." "." ".tabName(v:val)')),
\   'sink':    function('<sid>jumpToTab'),
\ })<CR>
```

`fzf#run` is the core of Vim integration. It takes a list of string itmes from
`source` and shows them in fzf windows. One or multiple items are chosen by you
and sent as parameter to `sink` which usually is a vim function to do whatever
you want to do with the chosen items.

Here, `source` gets a list of strings whose format is `tabnumber tabname`.
The tab name can be got by function `tabName`.
`jumpToTab` at `sink` receives the selected item, gets the tab number
using `split` and then execute command `:normal 2gt` if the tab number is 2.

[1]: https://github.com/junegunn/fzf
[2]: https://github.com/junegunn/fzf/wiki/Examples-(vim)
[3]: https://github.com/junegunn/fzf.vim
