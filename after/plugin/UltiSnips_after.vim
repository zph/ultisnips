" File: UltiSnips_after.vim
" Author: Holger Rapp <SirVer@gmx.de>
" Description: Called after everything else to reclaim keys (Needed for
"              Supertab)
" NOCOM(#sirver): Remove last modifieds.
" Last Modified: July 27, 2009

if exists('did_UltiSnips_vim_after') || &cp || version < 700 || !exists("did_UltiSnips_vim") || !has("python")
	finish
endif

call UltiSnips_MapKeys_Master()

let did_UltiSnips_vim_after=1

