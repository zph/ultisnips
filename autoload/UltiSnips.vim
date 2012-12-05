if !exists('g:UltiSnips') | let g:UltiSnips = {} | endif | let s:c = g:UltiSnips

let s:did_setup = 0

" lazily setup Ultisnip, then call function
fun! UltiSnips#Setup(fun, ...)
  if !s:did_setup
    " Expand our path
    call s:c.Py("import vim, os, sys")
    call s:c.Py("sys.path.append(\"".escape(expand("<sfile>:h:h"),'"')."\")")
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

  return call(a:fun_, a:000)
endf

" }}}

function! CompensateForPUM()
    """ The CursorMovedI event is not triggered while the popup-menu is visible,
    """ and it's by this event that UltiSnips updates its vim-state. The fix is
    """ to explicitly check for the presence of the popup menu, and update
    """ the vim-state accordingly.
    if pumvisible()
        call s:c.Py("UltiSnips_Manager.cursor_moved()")
    endif
endfunction
function! UltiSnips#ExpandSnippet()
    call s:c.Py("UltiSnips_Manager.expand()")
    return ""
endfunction

function! UltiSnips#ExpandSnippetOrJump()
    call CompensateForPUM()
    call s:c.Py("UltiSnips_Manager.expand_or_jump()")
    return ""
endfunction

function! UltiSnips#ListSnippets()
    call s:c.Py("UltiSnips_Manager.list_snippets()")
    return ""
endfunction

function! UltiSnips#SaveLastVisualSelection()
    call s:c.Py("UltiSnips_Manager.save_last_visual_selection()")
    return ""
endfunction

function! UltiSnips#JumpBackwards()
    call CompensateForPUM()
    call s:c.Py("UltiSnips_Manager.jump_backwards()")
    return ""
endfunction

function! UltiSnips#JumpForwards()
    call CompensateForPUM()
    call s:c.Py("UltiSnips_Manager.jump_forwards()")
    return ""
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

