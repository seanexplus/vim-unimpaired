" unimpaired.vim - Pairs of handy bracket mappings
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      2.1
" GetLatestVimScripts: 1590 1 :AutoInstall: unimpaired.vim
if (v:version < 802 || (v:version == 802 && !has('patch3434')))
	finish
endif
" 初始化vim 9 script
vim9script
if exists("g:loaded_unimpaired") || &cp || v:version < 700
  finish
endif
g:loaded_unimpaired = 1

def Map(...argv: list<string>): string
  var [mode, head, rhs] = [argv[0], argv[1], argv[2]]
  var rest = argv[3 :]
  var flags = get(rest, 0, '') .. (rhs =~# '^<Plug>' ? '' : '<script>')
  var tail = ''
  var keys = get(g:, mode .. 'remap', {})
  if type(keys) == type({}) && !empty(keys)
    while !empty(head) && len(keys)
      if has_key(keys, head)
        head = keys[head]
        if empty(head)
          head = '<skip>'
        endif
        break
      endif
      tail = matchstr(head, '<[^<>]*>$\|.$') .. tail
      head = substitute(head, '<[^<>]*>$\|.$', '', '')
    endwhile
  endif
  if head !=# '<skip>' && empty(maparg(head .. tail, mode))
    return mode .. 'map ' .. flags .. ' ' .. head .. tail .. ' ' .. rhs
  endif
  return ''
enddef

# Section: Next and previous

def MapNextFamily(map: string, cmd: string, current: string): void
  var prefix = '<Plug>(unimpaired-' .. cmd
  var tmap = '<Plug>unimpaired' .. toupper(map)
  var tcmd = '".(v:count ? v:count : "")."' .. cmd
  var zv = (cmd ==# 'l' || cmd ==# 'c' ? 'zv' : '')
  var end = '"<CR>' .. zv
  execute 'nnoremap <silent> ' .. prefix .. 'previous) :<C-U>exe "' .. tcmd .. 'previous' .. end
  execute 'nnoremap <silent> ' .. prefix .. 'next)     :<C-U>exe "' .. tcmd .. 'next' .. end
  execute 'nnoremap ' .. prefix .. 'first)    :<C-U><C-R>=v:count ? v:count . "' .. current .. '" : "' .. cmd .. 'first"<CR><CR>' .. zv
  execute 'nnoremap ' .. prefix .. 'last)     :<C-U><C-R>=v:count ? v:count . "' .. current .. '" : "' .. cmd .. 'last"<CR><CR>' .. zv
  execute 'nnoremap <silent> ' .. tmap .. 'Previous :<C-U>exe "' .. tcmd .. 'previous' .. end
  execute 'nnoremap <silent> ' .. tmap .. 'Next     :<C-U>exe "' .. tcmd .. 'next' .. end
  execute 'nnoremap <silent> ' .. tmap .. 'First    :<C-U>exe "' .. tcmd .. 'first' .. end
  execute 'nnoremap <silent> ' .. tmap .. 'Last     :<C-U>exe "' .. tcmd .. 'last' .. end
  execute Map('n', '[' .. map, prefix .. 'previous)')
  execute Map('n', ']' .. map, prefix .. 'next)')
  execute Map('n', '[' .. toupper(map), prefix .. 'first)')
  execute Map('n', ']' .. toupper(map), prefix .. 'last)')
  if cmd ==# 'c' || cmd ==# 'l'
    execute 'nnoremap <silent> ' .. prefix .. 'pfile)  :<C-U>exe "' .. tcmd .. 'pfile' .. end
    execute 'nnoremap <silent> ' .. prefix .. 'nfile)  :<C-U>exe "' .. tcmd .. 'nfile' .. end
    execute 'nnoremap <silent> ' .. tmap .. 'PFile :<C-U>exe "' .. tcmd .. 'pfile' .. end
    execute 'nnoremap <silent> ' .. tmap .. 'NFile :<C-U>exe "' .. tcmd .. 'nfile' .. end
    execute Map('n', '[<C-' .. toupper(map) .. '>', prefix .. 'pfile)')
    execute Map('n', ']<C-' .. toupper(map) .. '>', prefix .. 'nfile)')
  elseif cmd ==# 't'
    nnoremap <silent> <Plug>(unimpaired-ptprevious) :<C-U>execute v:count1 .. "ptprevious"<CR>
    nnoremap <silent> <Plug>(unimpaired-ptnext) :<C-U>execute v:count1 .. "ptnext"<CR>
    execute 'nnoremap <silent> ' .. map .. 'PPrevious :<C-U>exe "p' .. tcmd .. 'previous' .. end
    execute 'nnoremap <silent> ' .. map .. 'PNext :<C-U>exe "p' .. tcmd .. 'next' .. end
    execute Map('n', '[<C-T>', '<Plug>(unimpaired-ptprevious)')
    execute Map('n', ']<C-T>', '<Plug>(unimpaired-ptnext)')
  endif
enddef

MapNextFamily('a', '', 'argument')
MapNextFamily('b', 'b', 'buffer')
MapNextFamily('l', 'l', 'll')
MapNextFamily('q', 'c', 'cc')
MapNextFamily('t', 't', 'trewind')

def Entries(path: string): list<string>
  var tpath = substitute(path, '[\\/]$', '', '')
  tpath = substitute(tpath, '[[$*]', '[&]', 'g')
  var files = split(glob(path .. "/.*"), "\n")
  files += split(glob(path .. "/*"), "\n")
  map(files, 'substitute(v:val, "[\\/]$", "", "")')
  filter(files, 'v:val !~# "[\\\\/]\\.\\.\\=$"')

  var filter_suffixes = substitute(escape(&suffixes, '~.*$^'), ',', '$\\|', 'g') .. '$'
  # filter(files, 'v:val !~# filter_suffixes')
  filter(files, (_, v) => v !~# filter_suffixes)

  return sort(files)
enddef

def FileByOffset(num: number): string
  var file = expand('%:p')
  if empty(file)
    file = getcwd() .. '/'
  endif
  var tnum = num
  while tnum != 0
    var files = Entries(fnamemodify(file, ':h'))
    if num < 0
      reverse(filter(files, (_, v) => v <# file))
    else
      filter(files, (_, v) => v ># file)
    endif
    var temp = get(files, 0, '')
    if empty(temp)
      file = fnamemodify(file, ':h')
    else
      file = temp
      var found = 1
      while isdirectory(file)
        files = Entries(file)
        if empty(files)
          found = 0
          break
        endif
        file = files[tnum > 0 ? 0 : -1]
      endwhile
      tnum += (tnum > 0 ? -1 : 1) * found
    endif
  endwhile
  return file
enddef

def Fnameescape(file: string): string
  if exists('*fnameescape')
    return fnameescape(file)
  else
    return escape(file," \t\n*?[{`$\\%#'\"|!<")
  endif
enddef

def GetWindow(): dict<any>
  if exists('*getwininfo') && exists('*win_getid')
    return get(getwininfo(win_getid()), 0, {})
  else
    return {}
  endif
enddef

def PreviousFileEntry(count: number): string
  var window = GetWindow()

  if get(window, 'loclist')
    return 'lolder ' .. count
  elseif get(window, 'quickfix')
    return 'colder ' .. count
  else
    return 'edit ' .. fnameescape(fnamemodify(FileByOffset(-v:count1), ':.'))
  endif
enddef

def NextFileEntry(count: number): string
  var window = GetWindow()

  if get(window, 'loclist')
    return 'lnewer ' .. count
  elseif get(window, 'quickfix')
    return 'cnewer ' .. count
  else
	var command = 'edit ' .. fnameescape(fnamemodify(FileByOffset(v:count1), ':.'))
    return 'edit ' .. fnameescape(fnamemodify(FileByOffset(v:count1), ':.'))
  endif
enddef

nnoremap <silent> <Plug>(unimpaired-directory-next)     :<C-U>execute <SID>NextFileEntry(v:count1)<CR>
nnoremap <silent> <Plug>(unimpaired-directory-previous) :<C-U>execute <SID>PreviousFileEntry(v:count1)<CR>
nnoremap <silent> <Plug>unimpairedDirectoryNext     :<C-U>execute <SID>NextFileEntry(v:count1)<CR>
nnoremap <silent> <Plug>unimpairedDirectoryPrevious :<C-U>execute <SID>PreviousFileEntry(v:count1)<CR>
execute Map('n', ']f', '<Plug>(unimpaired-directory-next)')
execute Map('n', '[f', '<Plug>(unimpaired-directory-previous)')

# Section: Diff

nnoremap <silent> <Plug>(unimpaired-context-previous) :<C-U><ScriptCmd>Context(1)<CR>
nnoremap <silent> <Plug>(unimpaired-context-next)     :<C-U><ScriptCmd>Context(0)<CR>
vnoremap <silent> <Plug>(unimpaired-context-previous) :<C-U>execute 'normal! gv'<Bar><ScriptCmd>Context(1)<CR>
vnoremap <silent> <Plug>(unimpaired-context-next)     :<C-U>execute 'normal! gv'<Bar><ScriptCmd>Context(0)<CR>
onoremap <silent> <Plug>(unimpaired-context-previous) :<C-U><ScriptCmd>ContextMotion(1)<CR>
onoremap <silent> <Plug>(unimpaired-context-next)     :<C-U><ScriptCmd>ContextMotion(0)<CR>

execute Map('n', '[n', '<Plug>(unimpaired-context-previous)')
execute Map('n', ']n', '<Plug>(unimpaired-context-next)')
execute Map('x', '[n', '<Plug>(unimpaired-context-previous)')
execute Map('x', ']n', '<Plug>(unimpaired-context-next)')
execute Map('o', '[n', '<Plug>(unimpaired-context-previous)')
execute Map('o', ']n', '<Plug>(unimpaired-context-next)')

nnoremap <silent> <Plug>unimpairedContextPrevious :<C-U><ScriptCmd>Context(1)<CR>
nnoremap <silent> <Plug>unimpairedContextNext     :<C-U><ScriptCmd>Context(0)<CR>
xnoremap <silent> <Plug>unimpairedContextPrevious :<C-U>execute 'normal! gv'<Bar><ScriptCmd>Context(1)<CR>
xnoremap <silent> <Plug>unimpairedContextNext     :<C-U>execute 'normal! gv'<Bar><ScriptCmd>Context(0)<CR>
onoremap <silent> <Plug>unimpairedContextPrevious :<C-U><ScriptCmd>ContextMotion(1)<CR>
onoremap <silent> <Plug>unimpairedContextNext     :<C-U><ScriptCmd>ContextMotion(0)<CR>

def Context(reverse: bool): number
  search('^\(@@ .* @@\|[<=>|]\{7}[<=>|]\@!\)', reverse ? 'bW' : 'W')
enddef

def ContextMotion(reverse: bool): void
  if reverse
    -
  endif
  search('^@@ .* @@\|^diff \|^[<=>|]\{7}[<=>|]\@!', 'bWc')
  var end = 0
  if getline('.') =~# '^diff '
    end = search('^diff ', 'Wn') - 1
    if end < 0
      end = line('$')
    endif
  elseif getline('.') =~# '^@@ '
    end = search('^@@ .* @@\|^diff ', 'Wn') - 1
    if end < 0
      end = line('$')
    endif
  elseif getline('.') =~# '^=\{7\}'
    +
    end = search('^>\{7}>\@!', 'Wnc')
  elseif getline('.') =~# '^[<=>|]\{7\}'
    end = search('^[<=>|]\{7}[<=>|]\@!', 'Wn') - 1
  else
    return
  endif
  if end > line('.')
    execute 'normal! V' .. (end - line('.')) .. 'j'
  elseif end == line('.')
    normal! V
  endif
enddef

# Section: Line operations

def BlankUp(): string
  var cmd = $'put!=repeat(nr2char(10), {v:count1})|silent '']+'
  if &modifiable
    cmd = cmd .. $'|silent! call repeat#set("\<Plug>(unimpaired-blank-up)", {v:count1})'
  endif
  return cmd
enddef

def BlankDown(): string
  var cmd = $'put =repeat(nr2char(10), {v:count1})|silent ''[-'
  if &modifiable
    cmd = cmd .. $'|silent! call repeat#set("\<Plug>(unimpaired-blank-down)", {v:count1})'
  endif
  return cmd
enddef

nnoremap <silent> <Plug>(unimpaired-blank-up)   :<C-U>execute <SID>BlankUp()<CR>
nnoremap <silent> <Plug>(unimpaired-blank-down) :<C-U>execute <SID>BlankDown()<CR>

nnoremap <silent> <Plug>unimpairedBlankUp   :<C-U>execute <SID>BlankUp()<CR>
nnoremap <silent> <Plug>unimpairedBlankDown :<C-U>execute <SID>BlankDown()<CR>

execute Map('n', '[<Space>', '<Plug>(unimpaired-blank-up)')
execute Map('n', ']<Space>', '<Plug>(unimpaired-blank-down)')

def ExecMove(cmd: string): void
  var old_fdm = &foldmethod
  if old_fdm !=# 'manual'
    &foldmethod = 'manual'
  endif
  normal! m`
  silent! execute cmd
  normal! ``
  if old_fdm !=# 'manual'
    &foldmethod = old_fdm
  endif
enddef

def Move(cmd: string, count: number, map: string): void
  ExecMove('move ' .. cmd .. count)
  if exists('*repeat#set')
    silent! repeat#set("\<Plug>(unimpaired-move-" .. map .. ")", count)
  endif
enddef

def MoveSelectionUp(count: number): void
  ExecMove("'<,'> move '<--" .. count)
  if exists('*repeat#set')
    silent! repeat#set("\<Plug>(unimpaired-move-selection-up)", count)
  endif
enddef

def MoveSelectionDown(count: number): void
  ExecMove("'<,'> move '>+" .. count)
  if exists('*repeat@set')
    silent! repeat#set("\<Plug>(unimpaired-move-selection-down)", count)
  endif
enddef

nnoremap <Plug>(unimpaired-move-up)            :<C-U><ScriptCmd>Move('--', v:count1, 'up')<CR><CR>
nnoremap <Plug>(unimpaired-move-down)          :<C-U><ScriptCmd>Move('+', v:count1, 'down')<CR><CR>
noremap  <silent> <Plug>(unimpaired-move-selection-up)   :<C-U><ScriptCmd>MoveSelectionUp(v:count1)<CR><CR>
noremap  <silent> <Plug>(unimpaired-move-selection-down) :<C-U><ScriptCmd>MoveSelectionDown(v:count1)<CR><CR>
nnoremap <silent> <Plug>unimpairedMoveUp            :<C-U><ScriptCmd>Move('--', v:count1, 'up')<CR><CR>
nnoremap <silent> <Plug>unimpairedMoveDown          :<C-U><ScriptCmd>Move('+', v:count1, 'down')<CR><CR>
noremap  <silent> <Plug>unimpairedMoveSelectionUp   :<C-U><ScriptCmd>MoveSelectionUp(v:count1)<CR><CR>
noremap  <silent> <Plug>unimpairedMoveSelectionDown :<C-U><ScriptCmd>MoveSelectionDown(v:count1)<CR><CR>

execute Map('n', '[e', '<Plug>(unimpaired-move-up)')
execute Map('n', ']e', '<Plug>(unimpaired-move-down)')
execute Map('x', '[e', '<Plug>(unimpaired-move-selection-up)')
execute Map('x', ']e', '<Plug>(unimpaired-move-selection-down)')

# Section: Option toggling

def StatuslineRefresh(): string
  &l:readonly = &l:readonly
  return ''
enddef

def Toggle(op: string): any
  StatuslineRefresh()
  return eval('&' .. op) ? 'no' .. op : op
enddef

def CursorOptions(): string
  return &cursorline && &cursorcolumn ? 'nocursorline nocursorcolumn' : 'cursorline cursorcolumn'
enddef

def Option_map(letter: string, option: string, mode: string): void
  execute 'nmap <script> <Plug>(unimpaired-enable)' .. letter ':<C-U>' .. mode .. ' ' .. option .. '<C-R>=<SID>StatuslineRefresh()<CR><CR>'
  execute 'nmap <script> <Plug>(unimpaired-disable)' .. letter ':<C-U>' .. mode .. ' no' .. option .. '<C-R>=<SID>StatuslineRefresh()<CR><CR>'
  execute 'nmap <script> <Plug>(unimpaired-toggle)' .. letter ':<C-U>' .. mode .. ' <C-R>=<SID>Toggle("' .. option .. '")<CR><CR>'
enddef

nmap <script> <Plug>(unimpaired-enable)b  :<C-U>set background=light<CR>
nmap <script> <Plug>(unimpaired-disable)b :<C-U>set background=dark<CR>
nmap <script> <Plug>(unimpaired-toggle)b  :<C-U>set background=<C-R>=&background == "dark" ? "light" : "dark"<CR><CR>
Option_map('c', 'cursorline', 'setlocal')
Option_map('-', 'cursorline', 'setlocal')
Option_map('_', 'cursorline', 'setlocal')
Option_map('u', 'cursorcolumn', 'setlocal')
Option_map('<Bar>', 'cursorcolumn', 'setlocal')
nmap <script> <Plug>(unimpaired-enable)d  :<C-U>diffthis<CR>
nmap <script> <Plug>(unimpaired-disable)d :<C-U>diffoff<CR>
nmap <script> <Plug>(unimpaired-toggle)d  :<C-U><C-R>=&diff ? "diffoff" : "diffthis"<CR><CR>
Option_map('h', 'hlsearch', 'set')
Option_map('i', 'ignorecase', 'set')
Option_map('l', 'list', 'setlocal')
Option_map('n', 'number', 'setlocal')
Option_map('r', 'relativenumber', 'setlocal')
Option_map('s', 'spell', 'setlocal')
Option_map('w', 'wrap', 'setlocal')
if empty(maparg('<Plug>(unimpaired-toggle)z', 'n'))
  Option_map('z', 'spell', 'setlocal')
endif
nmap <script> <Plug>(unimpaired-enable)v  :<C-U>set virtualedit+=all<CR>
nmap <script> <Plug>(unimpaired-disable)v :<C-U>set virtualedit-=all<CR>
nmap <script> <Plug>(unimpaired-toggle)v  :<C-U>set <C-R>=(&virtualedit =~# "all") ? "virtualedit-=all" : "virtualedit+=all"<CR><CR>
nmap <script> <Plug>(unimpaired-enable)x  :<C-U>set cursorline cursorcolumn<CR>
nmap <script> <Plug>(unimpaired-disable)x :<C-U>set nocursorline nocursorcolumn<CR>
nmap <script> <Plug>(unimpaired-toggle)x  :<C-U>set <C-R>=<SID>CursorOptions()<CR><CR>
nmap <script> <Plug>(unimpaired-enable)+  :<C-U>set cursorline cursorcolumn<CR>
nmap <script> <Plug>(unimpaired-disable)+ :<C-U>set nocursorline nocursorcolumn<CR>
nmap <script> <Plug>(unimpaired-toggle)+  :<C-U>set <C-R>=<SID>CursorOptions()<CR><CR>

def ColorColumn(should_clear: bool): string
  if !empty(&colorcolumn)
    var colorcolumn = &colorcolumn
  endif
  return should_clear ? '' : get(, 'colorcolumn', get(g:, 'unimpaired_colorcolumn', '+1'))
enddef
nmap <script> <Plug>(unimpaired-enable)t  :<C-U>set colorcolumn=<C-R>=<SID>ColorColumn(0)<CR><CR>
nmap <script> <Plug>(unimpaired-disable)t :<C-U>set colorcolumn=<C-R>=<SID>ColorColumn(1)<CR><CR>
nmap <script> <Plug>(unimpaired-toggle)t  :<C-U>set colorcolumn=<C-R>=<SID>ColorColumn(!empty(&cc))<CR><CR>

execute Map('n', 'yo', '<Plug>(unimpaired-toggle)')
execute Map('n', '[o', '<Plug>(unimpaired-enable)')
execute Map('n', ']o', '<Plug>(unimpaired-disable)')
execute Map('n', 'yo<Esc>', '<Nop>')
execute Map('n', '[o<Esc>', '<Nop>')
execute Map('n', ']o<Esc>', '<Nop>')
execute Map('n', '=s', '<Plug>(unimpaired-toggle)')
execute Map('n', '<s', '<Plug>(unimpaired-enable)')
execute Map('n', '>s', '<Plug>(unimpaired-disable)')
execute Map('n', '=s<Esc>', '<Nop>')
execute Map('n', '<s<Esc>', '<Nop>')
execute Map('n', '>s<Esc>', '<Nop>')

var paste = &paste
var mouse = &mouse

def RestorePaste(): void
  if exists('paste')
    &paste = paste
    &mouse = mouse
    unlet paste
    unlet mouse
  endif
  autocmd! unimpaired_paste
enddef

def SetupPaste(): void
  paste = &paste
  mouse = &mouse
  set paste
  set mouse=
  augroup unimpaired_paste
    autocmd!
    autocmd InsertLeave * RestorePaste()
    if exists('##ModeChanged')
      autocmd ModeChanged *:n RestorePaste()
    else
      autocmd CursorHold,CursorMoved * RestorePaste()
    endif
  augroup END
enddef

nnoremap <silent> <Plug>unimpairedPaste :<ScriptCmd>SetupPaste()<CR>
nmap <script><silent> <Plug>(unimpaired-paste) :<C-U><ScriptCmd>SetupPaste()<CR>

nmap <script><silent> <Plug>(unimpaired-enable)p  :<C-U><ScriptCmd>SetupPaste()<CR>O
nmap <script><silent> <Plug>(unimpaired-disable)p :<C-U><ScriptCmd>SetupPaste()<CR>o
nmap <script><silent> <Plug>(unimpaired-toggle)p  :<C-U><ScriptCmd>SetupPaste()<CR>0C

# Section: Put

def Putline(how: string, map: string): void
  var [body, type] = [getreg(v:register), getregtype(v:register)]
  if type ==# 'V'
    execute 'normal! "' .. v:register .. how
  else
    setreg(v:register, body, 'l')
    execute 'normal! "' .. v:register .. how
    setreg(v:register, body, type)
  endif
  silent! repeat#set("\<Plug>(unimpaired-put-" .. map .. ")")
enddef

nnoremap <silent> <Plug>(unimpaired-put-above) :<ScriptCmd>Putline('[p', 'above')<CR>
nnoremap <silent> <Plug>(unimpaired-put-below) :<ScriptCmd>Putline(']p', 'below')<CR>
nnoremap <silent> <Plug>(unimpaired-put-above-rightward) :<C-U><ScriptCmd>Putline(v:count1 . '[p', 'Above')<CR>>']
nnoremap <silent> <Plug>(unimpaired-put-below-rightward) :<C-U><ScriptCmd>Putline(v:count1 . ']p', 'Below')<CR>>']
nnoremap <silent> <Plug>(unimpaired-put-above-leftward)  :<C-U><ScriptCmd>Putline(v:count1 . '[p', 'Above')<CR><']
nnoremap <silent> <Plug>(unimpaired-put-below-leftward)  :<C-U><ScriptCmd>Putline(v:count1 . ']p', 'Below')<CR><']
nnoremap <silent> <Plug>(unimpaired-put-above-reformat)  :<C-U><ScriptCmd>Putline(v:count1 . '[p', 'Above')<CR>=']
nnoremap <silent> <Plug>(unimpaired-put-below-reformat)  :<C-U><ScriptCmd>Putline(v:count1 . ']p', 'Below')<CR>=']
nnoremap <silent> <Plug>unimpairedPutAbove :<ScriptCmd>Putline('[p', 'above')<CR>
nnoremap <silent> <Plug>unimpairedPutBelow :<ScriptCmd>Putline(']p', 'below')<CR>

execute Map('n', '[p', '<Plug>(unimpaired-put-above)')
execute Map('n', ']p', '<Plug>(unimpaired-put-below)')
execute Map('n', '[P', '<Plug>(unimpaired-put-above)')
execute Map('n', ']P', '<Plug>(unimpaired-put-below)')

execute Map('n', '>P', "<Plug>(unimpaired-put-above-rightward)")
execute Map('n', '>p', "<Plug>(unimpaired-put-below-rightward)")
execute Map('n', '<P', "<Plug>(unimpaired-put-above-leftward)")
execute Map('n', '<p', "<Plug>(unimpaired-put-below-leftward)")
execute Map('n', '=P', "<Plug>(unimpaired-put-above-reformat)")
execute Map('n', '=p', "<Plug>(unimpaired-put-below-reformat)")

# Section: Encoding and decoding

def String_encode(str: string): string
  var map = {"\n": 'n', "\r": 'r', "\t": 't', "\b": 'b', "\f": '\f', '"': '"', '\': '\'}
  return substitute(str,"[\001-\033\\\\\"]",'\="\\".get(map,submatch(0),printf("%03o",char2nr(submatch(0))))','g')
enddef

def String_decode(str: string): string
  var map = {'n': "\n", 'r': "\r", 't': "\t", 'b': "\b", 'f': "\f", 'e': "\e", 'a': "\001", 'v': "\013", "\n": ''}
  var tstr = str
  if tstr =~# '^\s*".\{-\}\\\@<!\%(\\\\\)*"\s*\n\=$'
    tstr = substitute(substitute(tstr, '^\s*\zs"','',''),'"\ze\s*\n\=$', '', '')
  endif
  return substitute(tstr, '\\\(\o\{1,3\}\|x\x\{1,2\}\|u\x\{1,4\}\|.\)', '\=get(map,submatch(1),submatch(1) =~? "^[0-9xu]" ? nr2char("0".substitute(submatch(1),"^[Uu]","x","")) : submatch(1))', 'g')
enddef

def Url_encode(str: string): string
  # iconv trick to convert utf-8 bytes to 8bits indiviual char.
  return substitute(iconv(str, 'latin1', 'utf-8'), '[^A-Za-z0-9_.~-]', '\="%".printf("%02X",char2nr(submatch(0)))', 'g')
enddef

def Url_decode(str: string): string
  var tstr = substitute(substitute(substitute(str, '%0[Aa]\n$', '%0A', ''), '%0[Aa]', '\n', 'g'), '+', ' ', 'g')
  return iconv(substitute(tstr, '%\(\x\x\)', '\=nr2char("0x".submatch(1))','g'), 'utf-8', 'latin1')
enddef

# HTML entities {{{2

g:unimpaired_html_entities = {
      \ 'nbsp':     160, 'iexcl':    161, 'cent':     162, 'pound':    163,
      \ 'curren':   164, 'yen':      165, 'brvbar':   166, 'sect':     167,
      \ 'uml':      168, 'copy':     169, 'ordf':     170, 'laquo':    171,
      \ 'not':      172, 'shy':      173, 'reg':      174, 'macr':     175,
      \ 'deg':      176, 'plusmn':   177, 'sup2':     178, 'sup3':     179,
      \ 'acute':    180, 'micro':    181, 'para':     182, 'middot':   183,
      \ 'cedil':    184, 'sup1':     185, 'ordm':     186, 'raquo':    187,
      \ 'frac14':   188, 'frac12':   189, 'frac34':   190, 'iquest':   191,
      \ 'Agrave':   192, 'Aacute':   193, 'Acirc':    194, 'Atilde':   195,
      \ 'Auml':     196, 'Aring':    197, 'AElig':    198, 'Ccedil':   199,
      \ 'Egrave':   200, 'Eacute':   201, 'Ecirc':    202, 'Euml':     203,
      \ 'Igrave':   204, 'Iacute':   205, 'Icirc':    206, 'Iuml':     207,
      \ 'ETH':      208, 'Ntilde':   209, 'Ograve':   210, 'Oacute':   211,
      \ 'Ocirc':    212, 'Otilde':   213, 'Ouml':     214, 'times':    215,
      \ 'Oslash':   216, 'Ugrave':   217, 'Uacute':   218, 'Ucirc':    219,
      \ 'Uuml':     220, 'Yacute':   221, 'THORN':    222, 'szlig':    223,
      \ 'agrave':   224, 'aacute':   225, 'acirc':    226, 'atilde':   227,
      \ 'auml':     228, 'aring':    229, 'aelig':    230, 'ccedil':   231,
      \ 'egrave':   232, 'eacute':   233, 'ecirc':    234, 'euml':     235,
      \ 'igrave':   236, 'iacute':   237, 'icirc':    238, 'iuml':     239,
      \ 'eth':      240, 'ntilde':   241, 'ograve':   242, 'oacute':   243,
      \ 'ocirc':    244, 'otilde':   245, 'ouml':     246, 'divide':   247,
      \ 'oslash':   248, 'ugrave':   249, 'uacute':   250, 'ucirc':    251,
      \ 'uuml':     252, 'yacute':   253, 'thorn':    254, 'yuml':     255,
      \ 'OElig':    338, 'oelig':    339, 'Scaron':   352, 'scaron':   353,
      \ 'Yuml':     376, 'circ':     710, 'tilde':    732, 'ensp':    8194,
      \ 'emsp':    8195, 'thinsp':  8201, 'zwnj':    8204, 'zwj':     8205,
      \ 'lrm':     8206, 'rlm':     8207, 'ndash':   8211, 'mdash':   8212,
      \ 'lsquo':   8216, 'rsquo':   8217, 'sbquo':   8218, 'ldquo':   8220,
      \ 'rdquo':   8221, 'bdquo':   8222, 'dagger':  8224, 'Dagger':  8225,
      \ 'permil':  8240, 'lsaquo':  8249, 'rsaquo':  8250, 'euro':    8364,
      \ 'fnof':     402, 'Alpha':    913, 'Beta':     914, 'Gamma':    915,
      \ 'Delta':    916, 'Epsilon':  917, 'Zeta':     918, 'Eta':      919,
      \ 'Theta':    920, 'Iota':     921, 'Kappa':    922, 'Lambda':   923,
      \ 'Mu':       924, 'Nu':       925, 'Xi':       926, 'Omicron':  927,
      \ 'Pi':       928, 'Rho':      929, 'Sigma':    931, 'Tau':      932,
      \ 'Upsilon':  933, 'Phi':      934, 'Chi':      935, 'Psi':      936,
      \ 'Omega':    937, 'alpha':    945, 'beta':     946, 'gamma':    947,
      \ 'delta':    948, 'epsilon':  949, 'zeta':     950, 'eta':      951,
      \ 'theta':    952, 'iota':     953, 'kappa':    954, 'lambda':   955,
      \ 'mu':       956, 'nu':       957, 'xi':       958, 'omicron':  959,
      \ 'pi':       960, 'rho':      961, 'sigmaf':   962, 'sigma':    963,
      \ 'tau':      964, 'upsilon':  965, 'phi':      966, 'chi':      967,
      \ 'psi':      968, 'omega':    969, 'thetasym': 977, 'upsih':    978,
      \ 'piv':      982, 'bull':    8226, 'hellip':  8230, 'prime':   8242,
      \ 'Prime':   8243, 'oline':   8254, 'frasl':   8260, 'weierp':  8472,
      \ 'image':   8465, 'real':    8476, 'trade':   8482, 'alefsym': 8501,
      \ 'larr':    8592, 'uarr':    8593, 'rarr':    8594, 'darr':    8595,
      \ 'harr':    8596, 'crarr':   8629, 'lArr':    8656, 'uArr':    8657,
      \ 'rArr':    8658, 'dArr':    8659, 'hArr':    8660, 'forall':  8704,
      \ 'part':    8706, 'exist':   8707, 'empty':   8709, 'nabla':   8711,
      \ 'isin':    8712, 'notin':   8713, 'ni':      8715, 'prod':    8719,
      \ 'sum':     8721, 'minus':   8722, 'lowast':  8727, 'radic':   8730,
      \ 'prop':    8733, 'infin':   8734, 'ang':     8736, 'and':     8743,
      \ 'or':      8744, 'cap':     8745, 'cup':     8746, 'int':     8747,
      \ 'there4':  8756, 'sim':     8764, 'cong':    8773, 'asymp':   8776,
      \ 'ne':      8800, 'equiv':   8801, 'le':      8804, 'ge':      8805,
      \ 'sub':     8834, 'sup':     8835, 'nsub':    8836, 'sube':    8838,
      \ 'supe':    8839, 'oplus':   8853, 'otimes':  8855, 'perp':    8869,
      \ 'sdot':    8901, 'lceil':   8968, 'rceil':   8969, 'lfloor':  8970,
      \ 'rfloor':  8971, 'lang':    9001, 'rang':    9002, 'loz':     9674,
      \ 'spades':  9824, 'clubs':   9827, 'hearts':  9829, 'diams':   9830,
      \ 'apos':      39}

# }}}2

def Xml_encode(str: string): string
  var tstr = str
  tstr = substitute(tstr,'&', '\&amp;', 'g')
  tstr = substitute(tstr,'<', '\&lt;', 'g')
  tstr = substitute(tstr,'>', '\&gt;', 'g')
  tstr = substitute(tstr, '"', '\&quot;', 'g')
  tstr = substitute(tstr, "'", '\&apos;', 'g')
  return tstr
enddef

def Xml_entity_decode(str: string): string
  var tstr = substitute(str, '\c&#\%(0*38\|x0*26\);', '&amp;', 'g')
  tstr = substitute(tstr, '\c&#\(\d\+\);', '\=nr2char(submatch(1))', 'g')
  tstr = substitute(tstr, '\c&#\(x\x\+\);', '\=nr2char("0".submatch(1))', 'g')
  tstr = substitute(tstr, '\c&apos;', "'", 'g')
  tstr = substitute(tstr, '\c&quot;', '"', 'g')
  tstr = substitute(tstr, '\c&gt;', '>', 'g')
  tstr = substitute(tstr, '\c&lt;', '<', 'g')
  tstr = substitute(tstr, '\C&\(\%(amp;\)\@!\w*\);', '\=nr2char(get(g:unimpaired_html_entities,submatch(1),63))', 'g')
  return substitute(tstr, '\c&amp;', '\&', 'g')
enddef

def Xml_decode(str: string): string
  var tstr = substitute(str, '<\%([[:alnum:]-]\+=\%("[^"]*"\|''[^'']*''\)\|.\)\{-\}>', '', 'g')
  return xml_entity_decode(tstr)
enddef

def Transform(algorithm: string, type: string): void
  var sel_save = &selection
  var cb_save = &clipboard
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  var reg_save = exists('*getreginfo') ? getreginfo('@') : getreg('@')
  if type ==# 'line'
    silent execute "normal! '[V']y"
    @@ = substitute(@@, "\n$", '', '')
  elseif type ==# 'block'
    silent execute "normal! `[\<C-V>`]y"
  else
    silent execute "normal! `[v`]y"
  endif
  if algorithm =~# '^\u\|#'
    @@ = {algorithm}(@@)
  else
    @@ = {algorithm}(@@)
  endif
  norm! gvp
  setreg('@', reg_save)
  &selection = sel_save
  &clipboard = cb_save
enddef

def TransformOpfunc(type: string): any
  return Transform(encode_algorithm, type)
enddef

def TransformSetup(algorithm: string): string
  encode_algorithm = algorithm
  &opfunc = matchstr(expand('<sfile>'), '<SNR>\d\+_') .. 'TransformOpfunc'
  return 'g@'
enddef

def UnimpairedMapTransform(algorithm: string, key: string): string
  var name = tr(algorithm, '_', '-')
  execute 'nnoremap <expr> <Plug>unimpaired_' .. algorithm .. ' <SID>TransformSetup("' .. algorithm .. '")'
  execute 'xnoremap <expr> <Plug>unimpaired_' ..  algorithm .. ' <SID>TransformSetup("' .. algorithm .. '")'
  execute 'nnoremap <expr> <Plug>unimpaired_line_' .. algorithm .. ' <SID>TransformSetup("' .. algorithm .. '")."_"'
  execute 'nnoremap <expr> <Plug>(unimpaired-' ..  name .. ') <SID>TransformSetup("' .. algorithm .. '")'
  execute 'xnoremap <expr> <Plug>(unimpaired-' ..  name .. ') <SID>TransformSetup("' .. algorithm .. '")'
  execute 'nnoremap <expr> <Plug>(unimpaired-' ..  name .. '-line) <SID>TransformSetup("' .. algorithm .. '")."_"'
  execute Map('n', key, '<Plug>(unimpaired-' .. name .. ')')
  execute Map('x', key, '<Plug>(unimpaired-' .. name .. ')')
  execute Map('n', key .. key[strlen(key) - 1], '<Plug>(unimpaired-' .. name .. '-line)')
  return ''
enddef

UnimpairedMapTransform('string_encode', '[y')
UnimpairedMapTransform('string_decode', ']y')
UnimpairedMapTransform('string_encode', '[C')
UnimpairedMapTransform('string_decode', ']C')
UnimpairedMapTransform('url_encode', '[u')
UnimpairedMapTransform('url_decode', ']u')
UnimpairedMapTransform('xml_encode', '[x')
UnimpairedMapTransform('xml_decode', ']x')

# vim:set sw=2 sts=2:
