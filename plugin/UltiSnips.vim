" File: UltiSnips.vim
" Author: Holger Rapp <SirVer@gmx.de>
" Description: The Ultimate Snippets solution for Vim
"
" Testing Info: {{{
"   See directions at the top of the test.py script located one 
"   directory above this file.
" }}}

" this kind of guard always annoys me .
" if exists('did_UltiSnips_vim') || &cp || version < 700
"    finish
" endif

" bind g:UltiSnips to local name s:c for convenience
if !exists('g:UltiSnips') | let g:UltiSnips = {} | endif | let s:c = g:UltiSnips

" Define dummy version of function called by autocommand setup in
" ftdetect/UltiSnips.vim.  If the function isn't defined (probably due to
" using a copy of vim without python support) it will cause an error anytime a
" new file is opened.
function! UltiSnips_FileTypeChanged()
endfunction

" Global Variables, user interface configuration {{{

" Should UltiSnips unmap select mode mappings automagically?
let s:c['RemoveSelectModeMappings'] = get(s:c, 'RemoveSelectModeMappings', 1)

" If UltiSnips should remove Mappings, which should be ignored
let s:c['MappingsToIgnore'] = get(s:c, 'MappingsToIgnore', [])

" A list of directory names that are searched for snippets.
let s:c['SnippetDirectories'] = get(s:c, 'SnippetDirectories', [ "UltiSnips" ] )

" UltiSnipsEdit will use this variable to decide if a new window
" is opened when editing. default is "normal", allowed are also
" "vertical", "horizontal"
let s:c['EditSplit'] = get(s:c, 'EditSplit', "normal" )

" use Snipmate like or UltiSnips like interface?
" values: UltiSnips or Snipmate
let s:c['InterfaceFlavour'] = get(s:c, 'InterfaceFlavour', "UltiSnips" )

" select python version, be backward compatible
" in the future just set PyCommand yourself
if exists('g:UsePythonVersion')
  let s:c['PyCommand'] =  {2: ':py ', 3: ':py3 '}[g:UsePythonVersion]
endif

" which :py* command should be used? Options:
" :py
" :py3
if !has_key(s:c, 'PyCommand')
  " try to detect working python version
  try
    " try python3
    py3 import vim; vim.command('let g:UltiSnips.PyCommand = "py3 "')
  catch /.*/ 
    try
      " try python2
      py import vim; vim.command('let g:UltiSnips.PyCommand = "py "')
    catch /.*/ | endtry
  endtry
endif
if !has_key(s:c, 'PyCommand')
  " what should happen if the selected version by the users is does not work?
  " probably it should be a lazy failure telling the user about the issue if
  " he tries to expand a snippet. Having a strong failure here may be annoying
  " echom at least writes to the :messages log, too.
  echom "UltiSnips: no valid python found implementation found"
endif

" short description for keys:
" ExpandTrigger: NOTE: expansion and forward jumping can, but needn't be the same trigger
" ListSnippets:  match in the current position.
" JumpForwardTrigger: NOTE: expansion and forward jumping can, but needn't be the same trigger
" JumpBackwardTrigger:  The trigger to jump backward inside a snippet

let s:InterfaceFlavours = {}
" Snipate like interface
let s:InterfaceFlavours['SnipMate'] = {
      \  'ExpandTrigger' : "<tab>",
      \  'ListSnippets' : "<c-r><tab>",
      \  'JumpForwardTrigger' : "<tab>",
      \  'JumpBackwardTrigger' : "<s-tab>",
   \ }

" UltiSnips like interface
let s:InterfaceFlavours['UltiSnips'] = {
      \  'ExpandTrigger' : "<tab>",
      \  'ListSnippets' : "<c-tab>",
      \  'JumpForwardTrigger' : "<c-j>",
      \  'JumpBackwardTrigger' : "<c-k>",
  \  }
if index(keys(s:InterfaceFlavours), s:c['InterfaceFlavour']) == -1
    echoe "bad value for g:UltiSnips['InterfaceFlavour']: ".s:c['InterfaceFlavour']." valid options: ".string(keys(s:InterfaceFlavours))
endif

" merge flavour configuration into configuration dictionary keeping
" existing settings
call extend(s:c, s:InterfaceFlavours[s:c['InterfaceFlavour']], 'keep')

" be compatible to configuration style, if a g:UltiSnips* setting exists assign it to
" dictionary overriding defaults
for k in keys(s:c)
    if exists('g:UltiSnips'.k)
	let s:c[k] = g:{'UltiSnips'.k}
    endif
endfor

" be compatible to code, assign all keys to global dictionaries (the code
" should be patched in the long run .., so this will go away)
for [k,v] in items(s:c)
    let g:{'UltiSnips'.k} = v
    unlet k v
endfor
" because Py is used only in this file we could even use a buffer local
" function. All code but user interface configuration should be moved to
" autoload anyway
fun! s:c.Py(command)
  if !has_key(s:c, 'PyCommand') | throw "no working python found" | endif
   exec s:c.PyCommand.a:command
endf
" }}}

" Global Commands {{{
function! UltiSnipsEdit(...)
    if a:0 == 1 && a:1 != ''
        let type = a:1
    else
	call 
        call s:c.Py("vim.command(\"let type = '%s'\" % UltiSnips_Manager.primary_filetype)")
    endif
    call s:c.Py("vim.command(\"let file = '%s'\" % UltiSnips_Manager.file_to_edit(vim.eval(\"type\")))")

    let mode = 'e'
    if exists('g:UltiSnipsEditSplit')
        if g:UltiSnipsEditSplit == 'vertical'
            let mode = 'vs'
        elseif g:UltiSnipsEditSplit == 'horizontal'
            let mode = 'sp'
        endif
    endif
    exe ':'.mode.' '.file
endfunction

" edit snippets, default of current file type or the specified type
command! -nargs=? UltiSnipsEdit :call UltiSnipsEdit(<q-args>)

" Global Commands {{{
function! UltiSnipsAddFiletypes(filetypes)
    call s:c.Py("UltiSnips_Manager.add_buffer_filetypes('" . a:filetypes . ".all')")
    return ""
endfunction
command! -nargs=1 UltiSnipsAddFiletypes :call UltiSnipsAddFiletypes(<q-args>)

"" }}}

" FUNCTIONS {{{
function! CompensateForPUM()
    """ The CursorMovedI event is not triggered while the popup-menu is visible,
    """ and it's by this event that UltiSnips updates its vim-state. The fix is
    """ to explicitly check for the presence of the popup menu, and update
    """ the vim-state accordingly.
    if pumvisible()
        call s:c.Py("UltiSnips_Manager.cursor_moved()")
    endif
endfunction
function! UltiSnips_ExpandSnippet()
    call s:c.Py("UltiSnips_Manager.expand()")
    return ""
endfunction

function! UltiSnips_ExpandSnippetOrJump()
    call CompensateForPUM()
    call s:c.Py("UltiSnips_Manager.expand_or_jump()")
    return ""
endfunction

function! UltiSnips_ListSnippets()
    call s:c.Py("UltiSnips_Manager.list_snippets()")
    return ""
endfunction

function! UltiSnips_SaveLastVisualSelection()
    call s:c.Py("UltiSnips_Manager.save_last_visual_selection()")
    return ""
endfunction

function! UltiSnips_JumpBackwards()
    call CompensateForPUM()
    call s:c.Py("UltiSnips_Manager.jump_backwards()")
    return ""
endfunction

function! UltiSnips_JumpForwards()
    call CompensateForPUM()
    call s:c.Py("UltiSnips_Manager.jump_forwards()")
    return ""
endfunction

function! UltiSnips_FileTypeChanged()
    call s:c.Py("UltiSnips_Manager.reset_buffer_filetypes()")
    call s:c.Py("UltiSnips_Manager.add_buffer_filetypes('" . &ft . "')")
    return ""
endfunction

function! UltiSnips_AddSnippet(trigger, value, descr, options, ...)
    " Takes the same arguments as SnippetManager.add_snippet:
    " (trigger, value, descr, options, ft = "all", globals = None)
    call s:c.Py("args = vim.eval(\"a:000\")")
    call s:c.Py("trigger = vim.eval(\"a:trigger\")")
    call s:c.Py("value = vim.eval(\"a:value\")")
    call s:c.Py("descr = vim.eval(\"a:descr\")")
    call s:c.Py("options = vim.eval(\"a:options\")")
    call s:c.Py("UltiSnips_Manager.add_snippet(trigger, value, descr, options, *args)")
    return ""
endfunction

function! UltiSnips_Anon(value, ...)
    " Takes the same arguments as SnippetManager.expand_anon:
    " (value, trigger="", descr="", options="", globals = None)
    call s:c.Py("args = vim.eval(\"a:000\")")
    call s:c.Py("value = vim.eval(\"a:value\")")
    call s:c.Py("UltiSnips_Manager.expand_anon(value, *args)")
    return ""
endfunction

function! UltiSnips_MapKeys()
    " Map the keys correctly
    if g:UltiSnipsExpandTrigger == g:UltiSnipsJumpForwardTrigger

        exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=UltiSnips_ExpandSnippetOrJump()<cr>"
        exec "snoremap <silent> " . g:UltiSnipsExpandTrigger . " <Esc>:call UltiSnips_ExpandSnippetOrJump()<cr>"
    else
        exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=UltiSnips_ExpandSnippet()<cr>"
        exec "snoremap <silent> " . g:UltiSnipsExpandTrigger . " <Esc>:call UltiSnips_ExpandSnippet()<cr>"
        exec "inoremap <silent> " . g:UltiSnipsJumpForwardTrigger  . " <C-R>=UltiSnips_JumpForwards()<cr>"
        exec "snoremap <silent> " . g:UltiSnipsJumpForwardTrigger  . " <Esc>:call UltiSnips_JumpForwards()<cr>"
    endif
    exec 'xnoremap ' . g:UltiSnipsExpandTrigger. ' :call UltiSnips_SaveLastVisualSelection()<cr>gvs'
    exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=UltiSnips_JumpBackwards()<cr>"
    exec "snoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <Esc>:call UltiSnips_JumpBackwards()<cr>"
    exec "inoremap <silent> " . g:UltiSnipsListSnippets . " <C-R>=UltiSnips_ListSnippets()<cr>"
    exec "snoremap <silent> " . g:UltiSnipsListSnippets . " <Esc>:call UltiSnips_ListSnippets()<cr>"

    snoremap <silent> <BS> <c-g>c
    snoremap <silent> <DEL> <c-g>c
    snoremap <silent> <c-h> <c-g>c
endf

function! UltiSnips_CursorMoved()
    call s:c.Py("UltiSnips_Manager.cursor_moved()")
endf
function! UltiSnips_EnteredInsertMode()
    call s:c.Py("UltiSnips_Manager.entered_insert_mode()")
endf
function! UltiSnips_LeavingBuffer()
    call s:c.Py("UltiSnips_Manager.leaving_buffer()")
endf
" }}}

"" STARTUP CODE {{{

" Expand our path
call s:c.Py("import vim, os, sys")
call s:c.Py("sys.path.append(\"".escape(expand("<sfile>:h"),'"')."\")")
call s:c.Py("from UltiSnips import UltiSnips_Manager")
call s:c.Py("UltiSnips_Manager.expand_trigger = vim.eval('g:UltiSnipsExpandTrigger')")
call s:c.Py("UltiSnips_Manager.forward_trigger = vim.eval('g:UltiSnipsJumpForwardTrigger')")
call s:c.Py("UltiSnips_Manager.backward_trigger = vim.eval('g:UltiSnipsJumpBackwardTrigger')")

au CursorMovedI * call UltiSnips_CursorMoved()
au CursorMoved * call UltiSnips_CursorMoved()
au BufLeave * call UltiSnips_LeavingBuffer()

call UltiSnips_MapKeys()

let did_UltiSnips_vim=1

" }}}
" vim: ts=8 sts=4 sw=4 expandtab
