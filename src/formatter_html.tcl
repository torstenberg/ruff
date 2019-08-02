# Copyright (c) 2019, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Html {
    superclass ::ruff::formatter::Formatter

    # Data members
    variable Document;        # Current document
    variable DocumentNamespace; # Namespace being documented
    variable Header;          # Common header
    variable Footer;          # Common footer
    variable NavigationLinks; # Navigation links forming ToC
    variable HeaderLevels;    # Header levels for various headers
    variable CssClasses;      # CSS classes for various elements

    constructor args {
        set HeaderLevels {
            class 3
            proc 4
            method 4
            nonav 5
            parameters 5
        }
        set CssClasses {
            class ruffclass
            proc  ruffproc
            method ruffmethod
        }
        next {*}$args
    }

    method NewSourceId {} {
        # Returns a new id to use for a source listing.
        variable SourceIdCounter
        if {![info exists SourceIdCounter]} {
            set SourceIdCounter 0
        }
        return [incr SourceIdCounter]
    }

    method Anchor args {
        # Construct an anchor from the passed arguments.
        #  args - String from which the anchor is to be constructed.
        # The anchor is formed by joining the passed strings with separators.
        # Empty arguments are ignored.
        # Returns an HTML-escaped anchor without the `#` prefix.
        set parts [lmap arg $args {
            if {$arg eq ""} continue
            set arg
        }]

        return [regsub -all {[^-:\w_.]} [join $parts -] _]
    }

    method HeadingReference {ns heading} {
        # Implements the [Formatter.HeadingReference] method for HTML.
        return "[ns_file_base $ns]#[my Anchor $ns $heading]"
    }

    method SymbolReference {ns symbol} {
        # Implements the [Formatter.SymbolReference] method for HTML.
        set ref [ns_file_base $ns]
        # Reference to the global namespace is to the file itself.
        if {$ns eq "::" && $symbol eq ""} {
            return $ref
        }
        return [append ref "#[my Anchor $symbol]"]
    }

    method Begin {} {
        # Implements the [Formatter.Begin] method for HTML.

        # Generate the header used by all files
        # set Header {<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">}
        set Header "<!DOCTYPE html>"
        append Header "<html><head><meta charset=\"utf-8\"/>\n"
        # append Header "<link rel='stylesheet' href='https://fonts.googleapis.com/css?family=Open+Sans|Noto+Serif|Droid+Sans+Mono'>"
        set titledesc [my Option -titledesc]
        append Header "<title>$titledesc</title>\n"
        if {[my Option? -stylesheets stylesheets]} {
            append Header "<style>\n$yui_style\n</style>\n"
            foreach url $stylesheets {
                append Header "<link rel='stylesheet' type='text/css' href='$url' />"
            }
        } else {
            # Use built-in styles
            append Header "<style>\n" \
                [read_ruff_file ruff-html.css] \
                "</style>\n"
        }
        append Header "<script>[read_ruff_file ruff-html.js]</script>"
        append Header "</head>\n<body>"

        # YUI stylesheet templates
        append Header "<div id='doc3' class='yui-t2'>"
        if {$titledesc ne ""} {
            append Header "<div id='hd' class='banner'>\n<a style='text-decoration:none;' href='[my SymbolReference :: {}]'>$titledesc</a>\n</div>\n"
        }
        append Header "<div id='bd'>"

        if {[my Option? -modulename modulename] && $modulename ne ""} {
            # TBD - do we need a modulename option?
          #  append Header [AddHeading 1 $modulename]
        }

        # Generate the Footer used by all files
        append Footer "</div>";        # <div id='bd'>
        append Footer "<div id='ft'>"
        append Footer "<div style='float: right;'>Document generated by Ruff!</div>"
        if {[my Option? -copyright copyright]} {
            append Footer "<div>&copy; [my Escape $copyright]</div>"
        }
        append Footer "</div>\n"
        append Footer "</div>";        # <div id='doc3' ...>
        append Footer "</body></html>"

        return
    }

    method DocumentBegin {ns} {
        # See [Formatter.DocumentBegin].
        # ns - Namespace for this document.

        set    NavigationLinks [dict create]
        set    Document $Header
        set    DocumentNamespace $ns
        append Document "<div id='yui-main'><div class='yui-b'>"

        return
    }

    method DocumentEnd {} {
        # See [Formatter.DocumentEnd].

        # Close off <div class='yui-b'><div id=yui-main> from DocumentBegin
        append Document "</div></div>"

        # Add the navigation bits and footer
        my Navigation $DocumentNamespace
        append Document $Footer

        set doc $Document
        set Document ""
        return $doc
    }

    method AddProgramElementHeading {type fqn {tooltip {}}} {
        # Adds heading for a program element like procedure, class or method.
        #  type - One of `proc`, `class` or `method`
        #  fqn - Fully qualified name of element.
        #  tooltip - The tooltip lines, if any, to be displayed in the navigation pane.
        # In addition to adding the heading to the document, a link
        # is also added to the collection of navigation links.

        set level    [dict get $HeaderLevels $type]
        set ns       [namespace qualifiers $fqn]
        set anchor   [my Anchor $fqn]
        set linkinfo [dict create tag h$level href "#$anchor"]
        if {[llength $tooltip]} {
            set tip "[my ToHtml [string trim [join $tooltip { }]] $ns]\n"
            dict set linkinfo tip $tip
        }
        set name [namespace tail $fqn]
        dict set linkinfo label $name
        dict set NavigationLinks $anchor $linkinfo
        if {[string length $ns]} {
            set ns_link [my ToHtml [markup_reference $ns]]
            set heading "<a name='$anchor'>[my Escape $name]</a><span class='ns_scope'> \[${ns_link}\]</span>"
        } else {
            set heading "<a name='$anchor'>[my Escape $fqn]</a>"
        }
        append Document [my HeadingWithUplink $level $heading $ns [dict get $CssClasses $type]]
        return
    }

    method AddHeading {level text scope {tooltip {}}} {
        # See [Formatter.AddHeading].
        #  level   - The numeric or semantic heading level.
        #  text    - The heading text.
        #  scope   - The documentation scope of the content.
        #  tooltip - Tooltip to display in navigation link.

        if {![string is integer -strict $level]} {
            set level [dict get $HeaderLevels $level]
        }
        set do_link [expr {$level >= [dict get $HeaderLevels nonav] ? false : true}]

        if {$do_link} {
            set anchor [my Anchor $scope $text]
            set linkinfo [dict create tag h$level href "#$anchor"]
            if {$tooltip ne ""} {
                set tip "[my ToHtml [string trim [join $tooltip { }]] $scope]\n"
                dict set linkinfo tip $tip
            }
            dict set linkinfo label $text
            dict set NavigationLinks $anchor $linkinfo
            # NOTE: <a></a> empty because the text itself may contain anchors.
            set heading "<a name='$anchor'></a>[my ToHtml $text $scope]"
        } else {
            set heading [my ToHtml $text $scope]
        }
        append Document [my HeadingWithUplink $level $heading $scope]
        return
    }

    method AddParagraph {lines scope} {
        # See [Formatter.AddParagraph].
        #  lines  - The paragraph lines.
        #  scope - The documentation scope of the content.
        append Document "<p class='ruff'>[my ToHtml [string trim [join $lines { }]] $scope]</p>\n"
        return
    }

    method AddDefinitions {definitions scope {preformatted none}} {
        # See [Formatter.AddDefinitions].
        #  definitions  - List of definitions.
        #  scope        - The documentation scope of the content.
        #  preformatted - One of `none`, `both`, `term` or `definition`
        #                 indicating which fields of the definition are
        #                 are already formatted.
        append Document "<table class='ruff_deflist'>\n"
        foreach item $definitions {
            set def [join [dict get $item definition] " "]
            if {$preformatted in {none term}} {
                set def [my ToHtml $def $scope]
            }
            set term [dict get $item term]
            if {$preformatted in {none definition}} {
                set term [my ToHtml $term $scope]
            }
            append Document "<tr><td class='ruff_defitem'>" \
                $term \
                "</td><td class='ruff_defitem'>" \
                $def \
                "</td></tr>\n"
        }
        append Document "</table>\n"
        return
    }

    method AddBullets {bullets scope} {
        # See [Formatter.AddBullets].
        #  bullets  - The list of bullets.
        #  scope    - The documentation scope of the content.
        append Document "<ul class='ruff'>\n"
        foreach lines $bullets {
            append Document "<li>[my ToHtml [join $lines { }] $scope]</li>\n"
        }
        append Document "</ul>\n"
        return
    }

    method AddPreformattedText {text scope} {
        # See [Formatter.AddPreformattedText].
        #  text  - Preformatted text.
        #  scope - The documentation scope of the content.
        append Document "<pre class='ruff'>\n" \
            [my Escape $text] \
            "\n</pre>\n"
        return
    }

    method AddSynopsis {synopsis scope} {
        # Adds a Synopsis section to the document content.
        #  synopsis - List of two elements comprising the command portion
        #             and the parameter list.
        #  scope  - The documentation scope of the content.

        # my AddHeading nonav Synopsis $scope
        lassign $synopsis cmds params
        set cmds   "<span class='ruff_cmd'>[my Escape [join $cmds { }]]</span>"
        if {[llength $params]} {
            set params "<span class='ruff_arg'>[my Escape [join $params { }]]</span>"
        } else {
            set params ""
        }
        append Document "<div class='ruff_synopsis'>$cmds $params</div>\n"
        return
    }

    method AddSource {source scope} {
        # Adds a Source code section to the document content.
        #  source - Source code fragment.
        #  scope  - The documentation scope of the content.
        set src_id [my NewSourceId]
        append Document "<div class='ruff_source'>"
        append Document "<p class='ruff_source_link'>"
        append Document "<a id='l_$src_id' href=\"javascript:toggleSource('$src_id')\">Show source</a>"
        append Document "</p>\n"
        append Document "<div id='$src_id' class='ruff_dyn_src'><pre>[my Escape $source]</pre></div>\n"
        append Document "</div>";    # class='ruff_source'

        return
    }

    method AddProcedure {procinfo} {
        # See [Formatter.AddProcedure].
        #  procinfo - dictionary describing the procedure.
        dict with procinfo {
            # Creates the following locals
            #  proctype, display_name, fqn, synopsis, parameters, summary,
            #  body, seealso, returns, source
            #
            # Only the fqn and proctype are mandatory.
        }

        set scope [namespace qualifiers $fqn]
        if {[info exists summary]} {
            my AddProgramElementHeading proc $fqn $summary
            my AddParagraph $summary $scope
        } else {
            my AddProgramElementHeading proc $fqn
        }

        if {[info exists synopsis]} {
            my AddSynopsis $synopsis $scope
        }

        if {[info exists parameters]} {
            my AddParameters $parameters $scope
        }

        if {[info exists returns]} {
            my AddHeading nonav "Return value" $scope
            my AddParagraph $returns $scope
        }

        if {[info exists body] && [llength $body]} {
            my AddHeading nonav Description $scope
            my AddParagraphs $body $scope
        }

        if {[info exist seealso]} {
            my AddReferences $seealso $scope "See also"
        }

        if {[info exists source]} {
            my AddSource $source $scope
        }

        return
    }

    method Navigation {{highlight_ns {}}} {
        # Adds the navigation box to the document.
        #  highlight_ns - Namespace to be highlighted in navigation.

        set highlight_style "color: #006666;background-color: white; margin-left:-4px; padding-left:3px;padding-right:2px;"
        set main_title "Main page"
        set main_ref [ns_file_base {}]

        append Document "<div class='yui-b navbox'>"
        # If highlight_ns is empty, assume main page. Hack hack hack
        if {$highlight_ns eq ""} {
            append Document "<h1><a style='padding-top:2px;$highlight_style' href='$main_ref'>$main_title</a></h1>\n<hr>\n"
        } else {
            append Document "<h1><a style='padding-top:2px;' href='$main_ref'>$main_title</a></h1>\n<hr>\n"
        }

        if {[my Option -pagesplit none] ne "none"} {
            foreach ns [my SortedNamespaces] {
                set ref  [ns_file_base $ns]
                set text [string trimleft $ns :]
                if {$ns eq $highlight_ns} {
                    append Document "<h1><a style='$highlight_style' href='$ref'>$text</a></h1>\n"
                } else {
                    append Document "<h1><a href='$ref'>$text</a></h1>\n"
                }
            }
            append Document <hr>
        }

        # Add on the per-namespace navigation links
        if {[dict size $NavigationLinks]} {
            dict for {text link} $NavigationLinks {
                set label [my Escape [string trimleft [dict get $link label] :]]
                set tag  [dict get $link tag]
                set href [dict get $link href]
                if {[dict exists $link tip]} {
                    append Document "<$tag><a class='tooltip' href='$href'>$label<span>[dict get $link tip]</span></a></$tag>"
                } else {
                    append Document "<$tag><a href='$href'>$label</a></$tag>"
                }
            }
        }
        append Document "</div>"; # Close off <div yui-b navbox>
        return
    }

    method HeadingWithUplink {level heading scope {cssclass ruff}} {
        # Returns the HTML fragment wrapping the given heading.
        # level - heading level
        # heading - bare HTML fragment to use for heading
        # scope - the namespace scope to be used for uplinks
        #
        # If the heading level is less than 5, links to the namespace
        # and documentation top are inserted into the heading.

        set hlevel "h$level"
        if {$level >= 5} {
            # Plain header
            return "<$hlevel class='$cssclass'>$heading</$hlevel>"
        }

        if {$scope ne "" && [my Reference? $scope scope_ref]} {
            set links "<a href='[dict get $scope_ref ref]'>[namespace tail $scope]</a>, "
        }
        if {[my Option -pagesplit none] eq "none"} {
            append links "<a href='#top'>Top</a>"
        } else {
            append links "<a href='[my SymbolReference :: {}]'>Main</a>"
        }
        set links "<span class='tinylink'>$links</span>"
        # NOTE: the div needed to reset the float from links
        return "<$hlevel class='$cssclass'>$heading$links</$hlevel>\n<div style='clear:both;'></div>\n"
    }

    method Escape {s} {
        # Returns an HTML-escaped string.
        #  s - string to be escaped
        # Protects characters in $s against interpretation as
        # HTML special characters.
        #
        # Returns the escaped string

        return [string map {
            &    &amp;
            \"   &quot;
            <    &lt;
            >    &gt;
        } $s]
    }

    # Credits: tcllib/Caius markdown module
    method ToHtml {text {scope {}}} {
        set text [regsub -all -lineanchor {[ ]{2,}$} $text <br/>]
        set index 0
        set result {}

        set re_backticks   {\A`+}
        set re_whitespace  {\s}
        set re_inlinelink  {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\]\s*\(\s*((?:[^\s\)]+|\([^\s\)]+\))+)?(\s+([\"'])(.*)?\4)?\s*\)}
        set re_reflink     {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\](?:\s*\[((?:[^\]]|\[[^\]]*?\])*)\])?}
        set re_htmltag     {\A</?\w+\s*>|\A<\w+(?:\s+\w+=(?:\"[^\"]+\"|\'[^\']+\'))*\s*/?>}
        set re_autolink    {\A<(?:(\S+@\S+)|(\S+://\S+))>}
        set re_comment     {\A<!--.*?-->}
        set re_entity      {\A\&\S+;}

        while {[set chr [string index $text $index]] ne {}} {
            switch $chr {
                "\\" {
                    # ESCAPES
                    set next_chr [string index $text [expr $index + 1]]

                    if {[string first $next_chr {\`*_\{\}[]()#+-.!>|}] != -1} {
                        set chr $next_chr
                        incr index
                    }
                }
                {_} {
                    # Unlike Markdown, do not treat underscores as special char
                }
                {*} {
                    # EMPHASIS
                    if {[regexp $re_whitespace [string index $result end]] &&
                        [regexp $re_whitespace [string index $text [expr $index + 1]]]} \
                        {
                            #do nothing
                        } \
                        elseif {[regexp -start $index \
                                     "\\A(\\$chr{1,3})((?:\[^\\$chr\\\\]|\\\\\\$chr)*)\\1" \
                                     $text m del sub]} \
                        {
                            switch [string length $del] {
                                1 {
                                    append result "<em>[my ToHtml $sub $scope]</em>"
                                }
                                2 {
                                    append result "<strong>[my ToHtml $sub $scope]</strong>"
                                }
                                3 {
                                    append result "<strong><em>[my ToHtml $sub $scope]</em></strong>"
                                }
                            }

                            incr index [string length $m]
                            continue
                        }
                }
                {`} {
                    # CODE
                    regexp -start $index $re_backticks $text m
                    set start [expr $index + [string length $m]]

                    if {[regexp -start $start -indices $m $text m]} {
                        set stop [expr [lindex $m 0] - 1]

                        set sub [string trim [string range $text $start $stop]]

                        append result "<code>[my Escape $sub]</code>"
                        set index [expr [lindex $m 1] + 1]
                        continue
                    }
                }
                {!} -
                "[" {
                    # Note: "[", not {[} because latter messes Emacs indentation
                    # LINKS AND IMAGES
                    if {$chr eq {!}} {
                        set ref_type img
                    } else {
                        set ref_type link
                    }

                    set match_found 0
                    set css ""

                    if {[regexp -start $index $re_inlinelink $text m txt url ign del title]} {
                        # INLINE
                        incr index [string length $m]

                        set url [my Escape [string trim $url {<> }]]
                        set txt [my ToHtml $txt $scope]
                        set title [my ToHtml $title $scope]

                        set match_found 1
                    } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                        if {$lbl eq {}} {
                            set lbl [regsub -all {\s+} $txt { }]
                        }

                        if {[my ResolvableReference? $lbl $scope code_link]} {
                            # RUFF CODE REFERENCE
                            set url [my Escape [dict get $code_link ref]]
                            set txt [my Escape [dict get $code_link label]]
                            set title $txt
                            if {[dict get $code_link type] eq "symbol"} {
                                set css "class='ruff_cmd'"
                            }
                            incr index [string length $m]
                            set match_found 1
                        } else {
                            app::log_error "Warning: no target found for link \"$lbl\". Assuming markdown reference."
                            set lbl [string tolower $lbl]

                            if {[info exists ::Markdown::_references($lbl)]} {
                                lassign $::Markdown::_references($lbl) url title

                                set url [my Escape [string trim $url {<> }]]
                                set txt [my ToHtml $txt $scope]
                                set title [my ToHtml $title $scope]

                                # REFERENCED
                                incr index [string length $m]
                                set match_found 1
                            }
                        }
                    }
                    # PRINT IMG, A TAG
                    if {$match_found} {
                        if {$ref_type eq {link}} {
                            if {$title ne {}} {
                                append result "<a href=\"$url\" title=\"$title\" $css>$txt</a>"
                            } else {
                                append result "<a href=\"$url\" $css>$txt</a>"
                            }
                        } else {
                            if {$title ne {}} {
                                append result "<img src=\"$url\" alt=\"$txt\" title=\"$title\" $css/>"
                            } else {
                                append result "<img src=\"$url\" alt=\"$txt\" $css/>"
                            }
                        }

                        continue
                    }
                }
                {<} {
                    # HTML TAGS, COMMENTS AND AUTOLINKS
                    if {[regexp -start $index $re_comment $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    } elseif {[regexp -start $index $re_autolink $text m email link]} {
                        if {$link ne {}} {
                            set link [my Escape $link]
                            append result "<a href=\"$link\">$link</a>"
                        } else {
                            set mailto_prefix "mailto:"
                            if {![regexp "^${mailto_prefix}(.*)" $email mailto email]} {
                                # $email does not contain the prefix "mailto:".
                                set mailto "mailto:$email"
                            }
                            append result "<a href=\"$mailto\">$email</a>"
                        }
                        incr index [string length $m]
                        continue
                    } elseif {[regexp -start $index $re_htmltag $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    }

                    set chr [my Escape $chr]
                }
                {&} {
                    # ENTITIES
                    if {[regexp -start $index $re_entity $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    }

                    set chr [my Escape $chr]
                }
                {$} {
                    # Ruff extension - treat $var as variables name
                    # Note: no need to escape characters but do so
                    # if you change the regexp
                    if {[regexp -start $index {\$\w+} $text m]} {
                        append result "<code>$m</code>"
                        incr index [string length $m]
                        continue
                    }
                }
                {>} -
                {'} -
                "\"" {
                    # OTHER SPECIAL CHARACTERS
                    set chr [my Escape $chr]
                }
                default {}
            }
            append result $chr
            incr index
        }
        return $result
    }
}
