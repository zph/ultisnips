" File: UltiSnips.vim
" Author: Holger Rapp <SirVer@gmx.de>
" Description: The Ultimate Snippets solution for Vim
"
" Testing Info: {{{
"   See directions at the top of the test.py script located one
"   directory above this file.
" }}}

if !exists('g:UltiSnips') | let g:UltiSnips = {} | endif | let s:c = g:UltiSnips

" NOCOM(#sirver): the approach with the OmniFunc for the completion menu is
" very clever
let s:did_setup = 0

" <sfile> does not work inside functions :(
let s:base_directory = expand("<sfile>:h:h")

fun! UltiSnips#Setup()
  if !s:did_setup
    " Expand our path
    call s:c.Py("import vim, os, os.path, sys")
    call s:c.Py('sys.path.append(os.path.join("'.escape(s:base_directory,'"').'", "python"))')
    call s:c.Py("from UltiSnips import UltiSnips_Manager")
    call s:c.Py("UltiSnips_Manager.expand_trigger = vim.eval('g:UltiSnipsExpandTrigger')")
    call s:c.Py("UltiSnips_Manager.forward_trigger = vim.eval('g:UltiSnipsJumpForwardTrigger')")
    call s:c.Py("UltiSnips_Manager.backward_trigger = vim.eval('g:UltiSnipsJumpBackwardTrigger')")

    " TODO: do this lazily - only when the user uses UltiSnip the first time
    au CursorMovedI * call g:UltiSnips.Py("UltiSnips_Manager.cursor_moved()")
    au CursorMoved * call g:UltiSnips.Py("UltiSnips_Manager.cursor_moved()")
    au BufLeave * call g:UltiSnips.Py("UltiSnips_Manager.leaving_buffer()")

    if !exists("g:UltiSnipsUsePythonVersion")
        let g:_uspy=":py3 "
        if !has("python3")
            if !has("python")
                if !exists("g:UltiSnipsNoPythonWarning")
                    echo  "UltiSnips requires py >= 2.6 or any py3"
                endif
                finish
            endif
            let g:_uspy=":py "
        endif
        let g:UltiSnipsUsePythonVersion = "<tab>"
    else
        if g:UltiSnipsUsePythonVersion == 2
            let g:_uspy=":py "
        else
            let g:_uspy=":py3 "
        endif
    endif
    let s:did_setup = 1
  endif
endf
" }}}

" editing snippets {{{

" craete a list of files which could be valid snippet files according to
" ft_filter. Its used by UltiSnips#ChooseSnippetFileToEditDefaultImplementation()
fun! UltiSnips#SnippetFilesByRuntimepathEditable(type_dir, filetype)
  let result = []

  let d = s:c[a:type_dir.type .'_ft_filter']
  let ft_filter = get(d, a:filetype, d.default)

  for r in map(split(&rtp, ","), 'v:val . "/'.(a:type_dir.dir).'"')
    if has_key(ft_filter, 'dir-regex') && !substitute(fnamemodify(r,':h'), "\\", "/", "g") =~ ft_filter['dir-regex']
      continue
    endif
    let filetypes = map(copy(get(ft_filter, 'filetypes', ['FILETYPE'])), 'substitute(v:val, "FILETYPE", &filetype,"g")')
    call extend(result, map(filetypes, 'r."/".v:val.".snippets"'))
  endfor
  return result
endf

" this requires tlib
fun! UltiSnips#ChooseSnippetFileToEditDefaultImplementation(filetype)
  try
          call tlib#input#List('mi', '', [])
  catch /.*/
          throw "you're missing tlib library"
  endtry

  let files = []
  for type_dir in [ {'type': 'UltiSnips', 'dir' : 'UltiSnips'}, {'type': 'snipmate', 'dir' : 'snippets'} ]
      call extend(files, UltiSnips#SnippetFilesByRuntimepathEditable(type_dir, a:filetype))
  endfor

  let exists = map(filter(copy(files), 'filereadable(v:val)'), '"exists:".v:val')
  let notExists = map(filter(copy(files), '!filereadable(v:val)'), '"does not exist yet:".v:val')

  let all = exists + notExists
  let select = tlib#input#List('mi', 'select files to be opened in splits', all)
  " TODO: honor EditSplit
  for idx in select
    exec 'sp '.fnameescape(substitute(all[idx - 1], '[^:]*:','',''))
  endfor
endf

" }}}


" default implementation finding snippets {{{1

fun! UltiSnips#SnippetFilesByRuntimepath(dir)
  let files = []
  for dir in split(&runtimepath,',')
    call extend(files, split(glob(dir.'/'.a:dir.'/*.snippets'),"\n"))
  endfor
  return files
endf

" default implementation. If you don't like it you can override it
" (or use your own python implemenation, see SnippetFilesForCurrentExpansion
" configuration option
" returns such:
" {'snipmate': [ 'foo.snippets', 'bar.snippets' ], 'UltiSnips' : ['z.snippets'] }
" depending on filetype and (snipmate|UltiSnips)_ft_filter configuration
" setting
fun! UltiSnips#SnippetFilesForCurrentExpansionDefaultImplementation(filetype)
  let result = {}
  for type_dir in [ {'type': 'UltiSnips', 'dir' : 'UltiSnips'}, {'type': 'snipmate', 'dir' : 'snippets'} ]
      let files = UltiSnips#SnippetFilesByRuntimepath(type_dir.dir)
      let d = s:c[type_dir.type .'_ft_filter']
      let ft_filter = get(d, a:filetype, d.default)

      let filetypes = map(copy(get(ft_filter, 'filetypes', ['FILETYPE'])), 'substitute(v:val, "FILETYPE", a:filetype,"g")')

      " filetype filter
      let files = filter(copy(files), 'index(filetypes, fnamemodify(v:val, ":t:r")) != -1')
      " directory filter
      if has_key(ft_filter, 'dir-regex')
        call filter(files, 'substitute(fnamemodify(v:val, ":h"), "\\", "/", "g") =~ ft_filter["dir-regex"]')
      endif
      let result[type_dir.type] = files
  endfor
  return result
endf

" }}}

fun! CompensateForPUM()
    """ The CursorMovedI event is not triggered while the popup-menu is visible,
    """ and it's by this event that UltiSnips updates its vim-state. The fix is
    """ to explicitly check for the presence of the popup menu, and update
    """ the vim-state accordingly.
    if pumvisible()
        call s:c.Py("UltiSnips_Manager.cursor_moved()")
    endif
endfunction
function! UltiSnips#ExpandSnippet()
    exec g:_uspy "UltiSnips_Manager.expand()"
    return ""
endfunction

function! UltiSnips#ExpandSnippetOrJump()
    call CompensateForPUM()
    exec g:_uspy "UltiSnips_Manager.expand_or_jump()"
    return ""
endfunction

function! UltiSnips#ListSnippets()
    exec g:_uspy "UltiSnips_Manager.list_snippets()"
    return ""
endfunction

function! UltiSnips#SaveLastVisualSelection()
    exec g:_uspy "UltiSnips_Manager.save_last_visual_selection()"
    return ""
endfunction

function! UltiSnips#JumpBackwards()
    call CompensateForPUM()
    exec g:_uspy "UltiSnips_Manager.jump_backwards()"
    return ""
endfunction

function! UltiSnips#JumpForwards()
    call CompensateForPUM()
    exec g:_uspy "UltiSnips_Manager.jump_forwards()"
    return ""
endfunction

function! UltiSnips#FileTypeChanged()
    exec g:_uspy "UltiSnips_Manager.reset_buffer_filetypes()"
    exec g:_uspy "UltiSnips_Manager.add_buffer_filetypes('" . &ft . "')"
    return ""
endfunction

" NOCOM(#sirver): document the name change to autoload
" NOCOM(#sirver): revert to not using a dictionary for config
function! UltiSnips#AddSnippet(trigger, value, descr, options, ...)
    " Takes the same arguments as SnippetManager.add_snippet:
    " (trigger, value, descr, options, ft = "all", globals = None)
    " NOCOM(#sirver): understand how this calling works.
    " NOCOM(#sirver): maybe bring back g:_uspy
    exec "py " "args = vim.eval(\"a:000\")"
    exec "py " "trigger = vim.eval(\"a:trigger\")"
    exec "py " "value = vim.eval(\"a:value\")"
    exec "py " "descr = vim.eval(\"a:descr\")"
    exec "py " "options = vim.eval(\"a:options\")"
    exec "py " "UltiSnips_Manager.add_snippet(trigger, value, descr, options, *args)"
    return ""
endfunction

function! UltiSnips#Anon(value, ...)
    " Takes the same arguments as SnippetManager.expand_anon:
    " (value, trigger="", descr="", options="", globals = None)
    " NOCOM(#sirver): understand how this calling works.
    exec "py " "args = vim.eval(\"a:000\")"
    exec "py " "value = vim.eval(\"a:value\")"
    exec "py " "UltiSnips_Manager.expand_anon(value, *args)"
    return ""
endfunction
" }}}

fun! UltiSnips#CompleteSnippetTriggerFun(findstart, base)
  if a:findstart
      " TODO(#sirver) What are those magic constants?
      let g:a=787
    return col('.')
  else
      let g:x=787
    return s:c.completionItems
  endif
endf

fun! UltiSnips#ResetOmniFunc(s)
    let &l:omnifunc = a:s
    redraw
    return "\<c-n>\<c-p>"
endf

" vim: ts=8 sts=4 sw=4 expandtab
