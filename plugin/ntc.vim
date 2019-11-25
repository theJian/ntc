if exists('g:ntc_loaded')
    finish
endif
let g:ntc_loaded = 1

lua require 'ntc'
