" Interface  "{{{1
call textobj#user#plugin('conditions', {
\      '-': {
\        '*sfile*': expand('<sfile>:p'),
\        'select-a': 'ac',  '*select-a-function*': 's:select_a',
\        'select-i': 'ic',  '*select-i-function*': 's:select_i'
\      }
\    })

" Misc.  "{{{1
let s:ws = '\v^\s*'
let s:openers = '\zs(<if>|<while>|<for>)'
let s:continuators = '\zs(<else>)'
let s:start_pattern = s:ws . s:openers
let s:continuation_pattern = s:ws + '{\s*' + s:continuators
"let s:end_pattern = s:comment_escape . '\zs<}>'
"let s:skip_pattern = 'getline(".") =~ "\\v\\S\\s<(if|unless)>\\s\\S"'

function! s:find_positions(continue)
  let orig_pos = getpos('.')

  " Check if we are on the correct line already
  if getline('.') =~ s:start_pattern
    let start_pos = getpos('.')
  else
    " Search backwards but don't wrap
    call search(s:start_pattern, 'bW')
    let start_pos = getpos('.')

    " Cursor has not moved - no match found
    if start_pos == orig_pos
      return
    endif
  endif

  let end_pos = s:jump_to_match()

  if end_pos isnot 0
    if s:orig_inside_selection(orig_pos, start_pos, end_pos)
      return ['V', start_pos, end_pos]
    endif
  endif
endfunction

function! s:select_a()
  let positions = s:find_positions(1)
  if positions isnot 0
    return positions
  endif

function! s:select_i()
  let positions = s:find_positions(0)
  if positions isnot 0
    let [_, start, end] = positions
    let start[1] = start[1] + 1
    let end[1] = end[1] - 1
    return positions
  endif
endfunction

function! s:orig_inside_selection(orig, start, end)
  let line = a:orig[1]
  return line >= a:start[1] && line <= a:end[1]
endfunction

function! s:jump_to_match()
  " Go to the end of the line
  normal! $

  let pos = getpos('.')
  let char = getline('.')[pos[2] - 1]

  " Check if we are on a one line conditional
  if char == ';'
    return pos
  " If we are on a brace, we jump to the closing brace
  elseif char == "{"
    normal %
    return getpos('.')
    " Jump through else
  endif

  " Otherwise we have no valid match
endfunction
