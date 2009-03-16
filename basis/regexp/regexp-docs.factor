! Copyright (C) 2008, 2009 Doug Coleman, Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel strings help.markup help.syntax math regexp.parser regexp.ast ;
IN: regexp

ABOUT: "regexp"

ARTICLE: "regexp" "Regular expressions"
"The " { $vocab-link "regexp" } " vocabulary provides word for creating and using regular expressions."
{ $subsection { "regexp" "intro" } }
"The class of regular expressions:"
{ $subsection regexp }
"Basic usage:"
{ $subsection { "regexp" "syntax" } }
{ $subsection { "regexp" "options" } }
{ $subsection { "regexp" "construction" } }
{ $subsection { "regexp" "operations" } }
"Advanced topics:"
{ $vocab-subsection "Regular expression combinators" "regexp.combinators" }
{ $subsection { "regexp" "theory" } }
{ $subsection { "regexp" "deploy" } } ;

ARTICLE: { "regexp" "intro" } "A quick introduction to regular expressions"

;

ARTICLE: { "regexp" "construction" } "Constructing regular expressions"
"Most of the time, regular expressions are literals and the parsing word should be used, to construct them at parse time. This ensures that they are only compiled once, and gives parse time syntax checking."
{ $subsection POSTPONE: R/ }
"Sometimes, regular expressions need to be constructed at run time instead; for example, in a text editor, the user might input a regular expression to search for in a document."
{ $subsection <regexp> } 
{ $subsection <optioned-regexp> }
"Another approach is to use " { $vocab-link "regexp.combinators" } "." ;

ARTICLE: { "regexp" "syntax" } "Regular expression syntax"
"Regexp syntax is largely compatible with Perl, Java and extended POSIX regexps, but not completely. A new addition is the inclusion of a negation operator, with the syntax " { $snippet "(?~foo)" } " to match everything that does not match " { $snippet "foo" } "."
{ $heading "Characters" }
{ $heading "Character classes" }
{ $heading "Predefined character classes" }
{ $heading "Boundaries" }
{ $heading "Greedy quantifiers" }
{ $heading "Reluctant quantifiers" }
{ $heading "Posessive quantifiers" }
{ $heading "Logical operations" }
{ $heading "Lookaround" }
{ $heading "Unsupported features" }
"One missing feature is backreferences. This is because of a design decision to allow only regular expressions following the formal theory of regular languages. For more information, see " { $link { "regexp" "theory" } } ". You can create a new regular expression to match a particular string using " { $vocab-link "regexp.combinators" } " and group capture is available to extract parts of a regular expression match." $nl
"Another feature is Perl's " { $snippet "\\G" } " syntax, which references the previous match, is not included. This is because that sequence is inherently stateful, and Factor regexps don't hold state." $nl
"Additionally, none of the operations which embed code into a regexp are supported, as this would require the inclusion of the Factor parser and compiler in any application which wants to expose regexps to the user. None of the casing operations are included, for simplicity." ; ! Also describe syntax, from the beginning

ARTICLE: { "regexp" "options" } "Regular expression options"
"When " { $link { "regexp" "construction" } } ", various options can be provided. Options have single-character names. A string of options has one of the following two forms:"
{ $code "on" "on-off" }
"The latter syntax allows some options to be disabled. The " { $snippet "on" } " and " { $snippet "off" } " strings name options to be enabled and disabled, respectively."
$nl
"The following options are supported:"
{ $table
  { "i" { $link case-insensitive } }
  { "d" { $link unix-lines } }
  { "m" { $link multiline } }
  { "n" { $link multiline } }
  { "r" { $link reversed-regexp } }
  { "s" { $link dotall } }
  { "u" { $link unicode-case } }
  { "x" { $link comments } }
} ;

ARTICLE: { "regexp" "theory" } "The theory of regular expressions"
"Far from being just a practical tool invented by Unix hackers, regular expressions were studied formally before computer programs were written to process them." $nl
"A regular language is a set of strings that is matched by a regular expression, which is defined to have characters and the empty string, along with the operations concatenation, disjunction and Kleene star. Another way to define the class of regular languages is as the class of languages which can be recognized with constant space overhead, ie with a DFA. These two definitions are provably equivalent." $nl
"One basic result in the theory of regular language is that the complement of a regular language is regular. In other words, for any regular expression, there exists another regular expression which matches exactly the strings that the first one doesn't match." $nl
"This implies, by DeMorgan's law, that, if you have two regular languages, their intersection is also regular. That is, for any two regular expressions, there exists a regular expression which matches strings that match both inputs." $nl
"Traditionally, regular expressions on computer support an additional operation: backreferences. For example, the Perl regexp " { $snippet "/(.*)$1/" } " matches a string repated twice. If a backreference refers to a string with a predetermined maximum length, then the resulting language is still regular." $nl
"But, if not, the language is not regular. There is strong evidence that there is no efficient way to parse with backreferences in the general case. Perl uses a naive backtracking algorithm which has pathological behavior in some cases, taking exponential time to match even if backreferences aren't used. Additionally, expressions with backreferences don't have the properties with negation and intersection described above." $nl
"The Factor regular expression engine was built with the design decision to support negation and intersection at the expense of backreferences. This lets us have a guaranteed linear-time matching algorithm. Systems like Ragel and Lex also use this algorithm, but in the Factor regular expression engine, all other features of regexps are still present." ;

ARTICLE: { "regexp" "operations" } "Matching operations with regular expressions"
"Testing if a string matches a regular expression:"
{ $subsection matches? }
"Finding a match inside a string:"
{ $subsection re-contains? }
{ $subsection first-match }
"Finding all matches inside a string:"
{ $subsection count-matches }
{ $subsection all-matching-slices }
{ $subsection all-matching-subseqs }
"Splitting a string into tokens delimited by a regular expression:"
{ $subsection re-split }
"Replacing occurrences of a regular expression with a string:"
{ $subsection re-replace } ;

ARTICLE: { "regexp" "deploy" } "Regular expressions and the deploy tool"
"The " { $link "tools.deploy" } " tool has the option to strip out the optimizing compiler from the resulting image. Since regular expressions compile to Factor code, this creates a minor performance-related caveat."
$nl
"Regular expressions constructed at runtime from a deployed application will be compiled with the non-optimizing compiler, which is always available because it is built into the Factor VM. This will result in lower performance than when using the optimizing compiler."
$nl
"Literal regular expressions constructed at parse time do not suffer from this restriction, since the deployed application is loaded and compiled before anything is stripped out."
$nl
"None of this applies to deployed applications which include the optimizing compiler, or code running inside a development image."
{ $see-also "compiler" { "regexp" "construction" } "deploy-flags" } ;

HELP: <regexp>
{ $values { "string" string } { "regexp" regexp } }
{ $description "Creates a regular expression object, given a string in regular expression syntax. When it is first used for matching, a DFA is compiled, and this DFA is stored for reuse so it is only compiled once." } ;

HELP: <optioned-regexp>
{ $values { "string" string } { "options" "a string of " { $link { "regexp" "options" } } } { "regexp" regexp } }
{ $description "Given a string in regular expression syntax, and a string of options, creates a regular expression object. When it is first used for matching, a DFA is compiled, and this DFA is stored for reuse so it is only compiled once." } ;

HELP: R/
{ $syntax "R/ foo.*|[a-zA-Z]bar/options" }
{ $description "Literal syntax for a regular expression. When this syntax is used, the DFA is compiled at compile-time, rather than on first use. The syntax for the " { $snippet "options" } " string is documented in " { $link { "regexp" "options" } } "." } ;

HELP: regexp
{ $class-description "The class of regular expressions. To construct these, see " { $link { "regexp" "construction" } } "." } ;

HELP: matches?
{ $values { "string" string } { "regexp" regexp } { "?" "a boolean" } }
{ $description "Tests if the string as a whole matches the given regular expression." } ;

HELP: all-matching-slices
{ $values { "string" string } { "regexp" regexp } { "seq" "a sequence of slices of the input" } }
{ $description "Finds a sequence of disjoint substrings which each match the pattern. It chooses this by finding the leftmost longest match, and then the leftmost longest match which starts after the end of the previous match, and so on." } ;

HELP: count-matches
{ $values { "string" string } { "regexp" regexp } { "n" integer } }
{ $description "Counts how many disjoint matches the regexp has in the string, as made unambiguous by " { $link all-matching-slices } "." } ;

HELP: re-split
{ $values { "string" string } { "regexp" regexp } { "seq" "a sequence of slices of the input" } }
{ $description "Splits the input string into chunks separated by the regular expression. Each chunk contains no match of the regexp. The chunks are chosen by the strategy of " { $link all-matching-slices } "." } ;

HELP: re-replace
{ $values { "string" string } { "regexp" regexp } { "replacement" string } { "result" string } }
{ $description "Replaces substrings which match the input regexp with the given replacement text. The boundaries of the substring are chosen by the strategy used by " { $link all-matching-slices } "." } ;

HELP: first-match
{ $values { "string" string } { "regexp" regexp } { "slice/f" "the match, if one exists" } }
{ $description "Finds the first match of the regular expression in the string, and returns it as a slice. If there is no match, then " { $link f } " is returned." } ;

HELP: re-contains?
{ $values { "string" string } { "regexp" regexp } { "?" "a boolean" } }
{ $description "Determines whether the string has a substring which matches the regular expression given." } ;
