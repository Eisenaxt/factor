! Copyright (C) 2003, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: alien arrays generic hashtables io kernel math assocs
namespaces sequences strings io.styles vectors words
prettyprint.config splitting classes continuations
io.streams.nested accessors ;
IN: prettyprint.sections

! State
SYMBOL: position
SYMBOL: recursion-check
SYMBOL: pprinter-stack

SYMBOL: last-newline
SYMBOL: line-count
SYMBOL: end-printing
SYMBOL: indent

! We record vocabs of all words
SYMBOL: pprinter-in
SYMBOL: pprinter-use

: record-vocab ( word -- )
    word-vocabulary [ dup pprinter-use get set-at ] when* ;

! Utility words
: line-limit? ( -- ? )
    line-limit get dup [ line-count get <= ] when ;

: do-indent ( -- ) indent get CHAR: \s <string> write ;

: fresh-line ( n -- )
    dup last-newline get = [
        drop
    ] [
        last-newline set
        line-limit? [ "..." write end-printing get continue ] when
        line-count inc
        nl do-indent
    ] if ;

: text-fits? ( len -- ? )
    margin get dup zero?
    [ 2drop t ] [ >r indent get + r> <= ] if ;

! break only if position margin 2 / >
SYMBOL: soft

! always breaks
SYMBOL: hard

! Section protocol
GENERIC: section-fits? ( section -- ? )

GENERIC: short-section ( section -- )

GENERIC: long-section ( section -- )

GENERIC: indent-section? ( section -- ? )

GENERIC: unindent-first-line? ( section -- ? )

GENERIC: newline-after? ( section -- ? )

GENERIC: short-section? ( section -- ? )

! Sections
TUPLE: section
start end
start-group? end-group?
style overhang ;

: construct-section ( length class -- section )
    construct-empty
        position get >>start
        swap position [ + ] change
        position get >>end
        0 >>overhang ; inline

M: section section-fits? ( section -- ? )
    [ end>> last-newline get - ] [ overhang>> ] bi + text-fits? ;

M: section indent-section? drop f ;

M: section unindent-first-line? drop f ;

M: section newline-after? drop f ;

M: object short-section? section-fits? ;

: change-indent ( section n -- )
    swap indent-section? [ indent +@ ] [ drop ] if ;

: <indent ( section -- ) tab-size get change-indent ;

: indent> ( section -- ) tab-size get neg change-indent ;

: <fresh-line ( section -- )
    start>> fresh-line ;

: fresh-line> ( section -- )
    dup newline-after? [ end>> fresh-line ] [ drop ] if ;

: <long-section ( section -- )
    dup unindent-first-line?
    [ dup <fresh-line <indent ] [ dup <indent <fresh-line ] if ;

: long-section> ( section -- )
    dup indent> fresh-line> ;

: with-style* ( style quot -- )
    swap stdio [ <style-stream> ] change
    call stdio [ delegate ] change ; inline

: pprint-section ( section -- )
    dup short-section? [
        dup section-style [ short-section ] with-style*
    ] [
        dup <long-section
        dup section-style [ dup long-section ] with-style*
        long-section>
    ] if ;

! Break section
TUPLE: line-break < section type ;

: <line-break> ( type -- section )
    0 \ line-break construct-section
        swap >>type ;

M: line-break short-section drop ;

M: line-break long-section drop ;

! Block sections
TUPLE: block < section sections ;

: construct-block ( style class -- block )
    0 swap construct-section
        V{ } clone >>sections
        swap >>style ; inline

: <block> ( style -- block )
    block construct-block ;

: pprinter-block ( -- block ) pprinter-stack get peek ;

: add-section ( section -- )
    pprinter-block sections>> push ;

: last-section ( -- section )
    pprinter-block sections>>
    [ line-break? not ] find-last nip ;

: start-group ( -- )
    last-section t >>start-group? drop ;

: end-group ( -- )
    last-section t >>end-group? drop ;

: advance ( section -- )
    [ start>> last-newline get = not ]
    [ short-section? ] bi
    and [ bl ] when ;

: line-break ( type -- ) [ <line-break> add-section ] when* ;

M: block section-fits? ( section -- ? )
    line-limit? [ drop t ] [ call-next-method ] if ;

: pprint-sections ( block advancer -- )
    swap sections>> [ line-break? not ] subset
    unclip pprint-section [
        dup rot call pprint-section
    ] with each ; inline

M: block short-section ( block -- )
    [ advance ] pprint-sections ;

: do-break ( break -- )
    dup type>> hard eq?
    over section-end last-newline get - margin get 2/ > or
    [ <fresh-line ] [ drop ] if ;

: empty-block? ( block -- ? ) sections>> empty? ;

: if-nonempty ( block quot -- )
    >r dup empty-block? [ drop ] r> if ; inline

: (<block) pprinter-stack get push ;

: <block f <block> (<block) ;

: <object ( obj -- ) presented associate <block> (<block) ;

! Text section
TUPLE: text < section string ;

: <text> ( string style -- text )
    over length 1+ \ text construct-section
        swap >>style
        swap >>string ;

M: text short-section text-string write ;

M: text long-section short-section ;

: styled-text ( string style -- ) <text> add-section ;

: text ( string -- ) H{ } styled-text ;

! Inset section
TUPLE: inset < block narrow? ;

: <inset> ( narrow? -- block )
    H{ } inset construct-block
        2 >>overhang
        swap >>narrow? ;

M: inset long-section
    dup narrow?>> [
        [ <fresh-line ] pprint-sections
    ] [
        call-next-method
    ] if ;

M: inset indent-section? drop t ;

M: inset newline-after? drop t ;

: <inset ( narrow? -- ) <inset> (<block) ;

! Flow section
TUPLE: flow < block ;

: <flow> ( -- block )
    H{ } flow construct-block ;

M: flow short-section? ( section -- ? )
    #! If we can make room for this entire block by inserting
    #! a newline, do it; otherwise, don't bother, print it as
    #! a short section
    [ section-fits? ]
    [ [ end>> ] [ start>> ] bi - text-fits? not ] bi
    or ;

: <flow ( -- ) <flow> (<block) ;

! Colon definition section
TUPLE: colon < block ;

: <colon> ( -- block )
    H{ } colon construct-block ;

M: colon long-section short-section ;

M: colon indent-section? drop t ;

M: colon unindent-first-line? drop t ;

: <colon ( -- ) <colon> (<block) ;

: save-end-position ( block -- )
    position get >>end drop ;

: block> ( -- )
    pprinter-stack get pop
    [ [ save-end-position ] [ add-section ] bi ] if-nonempty ;

: with-section-state ( quot -- )
    [
        0 indent set
        0 last-newline set
        1 line-count set
        call
    ] with-scope ; inline

: do-pprint ( block -- )
    [
        [
            dup style>> [
                [ end-printing set dup short-section ] callcc0
            ] with-nesting drop
        ] if-nonempty
    ] with-section-state ;

! Long section layout algorithm
: chop-break ( seq -- seq )
    dup peek line-break? [ 1 head-slice* chop-break ] when ;

SYMBOL: prev
SYMBOL: next

: split-groups [ t , ] when ;

M: f section-start-group? drop t ;

M: f section-end-group? drop f ;

: split-before ( section -- )
    [ section-start-group? prev get section-end-group? and ]
    [ flow? prev get flow? not and ]
    bi or split-groups ;

: split-after ( section -- )
    section-end-group? split-groups ;

: group-flow ( seq -- newseq )
    [
        dup length [
            2dup 1- swap ?nth prev set
            2dup 1+ swap ?nth next set
            swap nth dup split-before dup , split-after
        ] with each
    ] { } make { t } split [ empty? not ] subset ;

: break-group? ( seq -- ? )
    [ first section-fits? ] [ peek section-fits? not ] bi and ;

: ?break-group ( seq -- )
    dup break-group? [ first <fresh-line ] [ drop ] if ;

M: block long-section ( block -- )
    [
        sections>> chop-break group-flow [
            dup ?break-group [
                dup line-break? [
                    do-break
                ] [
                    [ advance ] [ pprint-section ] bi
                ] if
            ] each
        ] each
    ] if-nonempty ;
