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

function! s:find_positions()
endfunction

function! s:select_a()
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

  if end_pos == []
    call setpos('.', orig_pos)
    return
  else
    return ['V', start_pos, end_pos]
  endif
endfunction

function! s:jump_to_match()
  " Go to the end of the line
  normal! $

  let pos = getpos('.')
  let char = getline('.')[getpos('.')[2] - 1]

  " Check if we are on a one line conditional
  if char == ';'
    return pos
  " If we are on a brace, we jump to the closing brace
  elseif char == "{"
    normal %
    return getpos('')
    " Jump through else
  " Otherwise we have no valid match
  else
    return []
  endif
endfunction
