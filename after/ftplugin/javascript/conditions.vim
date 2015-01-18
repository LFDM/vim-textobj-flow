" Interface  "{{{1
call textobj#user#plugin('conditions', {
\      '-': {
\        '*sfile*': expand('<sfile>:p'),
\        'select-a': 'ac',  '*select-a-function*': 's:select_a',
\        'select-i': 'ic',  '*select-i-function*': 's:select_i'
\      }
\    })

let s:opener_keywords = [
\      'if',
\      'while',
\      'for',
\      'try',
\      'switch'
\    ]

let s:continuator_keywords = [
\      'else',
\      'catch'
\    ]

function! s:to_regexp(arr)
  let start = '\zs('
  let elements = map(a:arr, '"<" . v:val . ">"')
  let end = ')'
  return start . join(elements, '|'). end
endfunction

let s:ws = '\v^\s*'
let s:openers = s:to_regexp(s:opener_keywords)
let s:continuators = '\}\s*' . s:to_regexp(s:continuator_keywords)

let s:start_pattern = s:ws . s:openers
let s:continuation_pattern = s:ws . s:continuators
let s:full_pattern = s:ws . '(' . s:openers. '|' . s:continuators. ')'


function! s:select_a()
  let positions = s:find_positions(1)
  if positions isnot 0
    return positions
  endif
endfunction

function! s:select_i()
  let positions = s:find_positions(0)
  if positions isnot 0
    let [_, start, end] = positions
    let start_line = start[1]
    let end_line   = end[1]

    " Special case when we are dealing with a one-line conditional!
    if start_line == end_line
      " Move across the condition
      normal! ^w
      normal %
      normal w
      let start = getpos('.')
      " Move to the end of the line, but don't take the semicolon.
      " If there is no semicolon this selection will look strange,
      " which is good, because it provides a hint to the user that
      " something is wrong with this line anyway
      normal! $h
      let end = getpos('.')
      return ['v', start, end]
    else
      let start[1] = start_line + 1
      let end[1] = end_line - 1
      return positions
    endif
  endif
endfunction

function! s:find_positions(around)
  let orig_pos = getpos('.')
  let pattern = a:around ? s:start_pattern : s:full_pattern
  echom pattern

  " Check if we are on the correct line already
  if getline('.') =~ pattern
    let start_pos = getpos('.')
    let end_pos = s:jump_to_match(a:around)
    return s:to_selector(start_pos, end_pos)

  " Search backwards but don't wrap to check if we're inside
  " a structure we're looking for
  else
    call search(pattern, 'bW')
    let start_pos = getpos('.')

    " Cursor has not moved - no match found
    if start_pos == orig_pos
      " Try to move forward
      return s:search_forward(orig_pos, pattern, a:around)
    else
      let end_pos = s:jump_to_match(a:around)

      " We found a match, but we have to check if our original
      " position was inside of this structure. If not this is no
      " valid match and we search forward again
      if s:orig_inside_selection(orig_pos, start_pos, end_pos)
        return s:to_selector(start_pos, end_pos)
      else
        return s:search_forward(orig_pos, pattern, a:around)
      endif
    endif
  endif
endfunction

function! s:search_forward(orig_pos, pattern, around)
  call setpos('.', a:orig_pos)
  call search(a:pattern, 'W')
  let start_pos = getpos('.')

  " Only continue if the cursor has moved
  if start_pos != a:orig_pos
    let end_pos = s:jump_to_match(a:around)
    return s:to_selector(start_pos, end_pos)
  endif
endfunction

function! s:to_selector(start_pos, end_pos)
  if a:start_pos isnot 0 && a:end_pos isnot 0
    return ['V', a:start_pos, a:end_pos]
  endif
endfunction

function! s:orig_inside_selection(orig, start, end)
  let line = a:orig[1]
  return line >= a:start[1] && line <= a:end[1]
endfunction

function! s:jump_to_match(continue)
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
    let pos = getpos('.')

    if a:continue
      " Include things like an else in an if condition
      return s:jump_to_continuator(pos)
    else
      return pos
    endif
  endif
endfunction

function! s:jump_to_continuator(pos)
  if getline('.') =~ s:continuation_pattern
    normal! $
    normal %
    return s:jump_to_continuator(getpos('.'))
  else
    return a:pos
  endif
endfunction
