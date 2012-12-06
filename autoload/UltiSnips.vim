if !exists('g:UltiSnips') | let g:UltiSnips = {} | endif | let s:c = g:UltiSnips

let s:did_setup = 0

" <sfile> does not work inside functions :(
let s:py_code = expand("<sfile>:h:h").'/py-code'

fun! UltiSnips#Setup()
  if !s:did_setup
    " Expand our path
    call s:c.Py("import vim, os, sys")
    call s:c.Py("sys.path.append(\"".escape(s:py_code,'"')."\")")
    call s:c.Py("from UltiSnips import UltiSnips_Manager")
    call s:c.Py("UltiSnips_Manager.expand_trigger = vim.eval('g:UltiSnipsExpandTrigger')")
    call s:c.Py("UltiSnips_Manager.forward_trigger = vim.eval('g:UltiSnipsJumpForwardTrigger')")
    call s:c.Py("UltiSnips_Manager.backward_trigger = vim.eval('g:UltiSnipsJumpBackwardTrigger')")

    " TODO: do this lazily - only when the user uses UltiSnip the first time
    au CursorMovedI * call g:UltiSnips.Py("UltiSnips_Manager.cursor_moved()")
    au CursorMoved * call g:UltiSnips.Py("UltiSnips_Manager.cursor_moved()")
    au BufLeave * call g:UltiSnips.Py("UltiSnips_Manager.leaving_buffer()")

    let s:did_setup = 1
  endif
endf

" lazily setup Ultisnip, then dispatch action to python's UltiSnips_Manager
" instance
" Allow calling CompensateForPUM for those actions requiring it
fun! UltiSnips#SetupM(c, s)
  call UltiSnips#Setup()
  if a:s == 'c'
    call CompensateForPUM()
  endif
  call s:c.Py("UltiSnips_Manager.".a:s)
  return ""
endf
" fun! UltiSnips#SetupV(fun, ...)
"   call UltiSnips#Setup()
"   return call('UltiSnips#'.a:fun, a:000)
" endf

" }}}

fun! UltiSnips#SnippetFilesByRuntimepath()
  let files = []
  for dir in split(&runtimepath,',')
    call extend(files, split(glob(dir.'/UltiSnips/*.snippets'),"\n"))
  endfor
  return files
endf

" default implementation. If you don't like it you can override it
" (or use your own python implemenation, see SnippetFilesForCurrentCurrentExpansion
" configuration option
fun! UltiSnips#SnippetFilesForCurrentCurrentExpansionDefaultImplementation(filetype)
  let files = UltiSnips#SnippetFilesByRuntimepath()
  let result = []
  for filter in get(s:c.ft_filter, a:filetype, s:c.ft_filter.default)
    let filter = substitute(filter,'FILETYPE', &filetype ,'')
    " for windows replace \ by / before matching against regex
    call extend(result, filter(copy(files), 'substitute(v:val, "\\\\","/","g")=~ filter'))
  endfor
  return result
endf

fun! CompensateForPUM()
    """ The CursorMovedI event is not triggered while the popup-menu is visible,
    """ and it's by this event that UltiSnips updates its vim-state. The fix is
    """ to explicitly check for the presence of the popup menu, and update
    """ the vim-state accordingly.
    if pumvisible()
        call s:c.Py("UltiSnips_Manager.cursor_moved()")
    endif
endfunction

function! UltiSnips#FileTypeChanged()
    call s:c.Py("UltiSnips_Manager.reset_buffer_filetypes()")
    call s:c.Py("UltiSnips_Manager.add_buffer_filetypes('" . &ft . "')")
    return ""
endfunction

function! UltiSnips#AddSnippet(...)
    " Takes the same arguments as SnippetManager.add_snippet:
    " (trigger, value, descr, options, ft = "all", globals = None)
    call s:c.Py("UltiSnips_Manager.add_snippet(vim.eval('a:000'))")
    return ""
endfunction

function! UltiSnips#Anon(...)
    " Takes the same arguments as SnippetManager.expand_anon:
    " (value, trigger="", descr="", options="", globals = None)
    call s:c.Py("UltiSnips_Manager.expand_anon(vim.eval('a:000'))")
    return ""
endfunction
" }}}

" vim: ts=8 sts=4 sw=4 expandtab
