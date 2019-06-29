# Copyright (c) 2009-2019, Ashok P. Nadkarni
# All rights reserved.
# See the file WOOF_LICENSE in the Woof! root directory for license


# Ruff! formatter for direct HTML

# TBD - in class summary table, constructor, destructor and
# forwarded methods are not getting linked properly.

namespace eval ruff::formatter::html {
    namespace path [list ::ruff ::ruff::private]

    # navlinks is used to build the navigation links that go on the
    # left side of a page. As such since all links are within the page,
    # only anchors need to be stored without the filename portion.
    # This is cleared for every page generation (in a multifile ouput).
    variable navlinks

    # link_targets maps a program element name to a file url.
    # Unlike navlinks, it is not cleared for every page
    # generation but rather content exists for the duration of a single
    # document generation. Also since the links may be across pages,
    # it includes the filename portion as well.
    variable link_targets

    # The header levels to use for various elements
    variable header_levels
    array set header_levels {
        class  3
        proc   4
        method 5
        nonav  6
    }

    # Css header classes to use for class and proc headers
    variable header_css
    array set header_css {
        class ruffclass
        proc  ruffproc
        method ruffmethod
    }

    # Note the Yahoo stylesheet is under a BSD license and hence
    # redistributable for all purposes
    variable yui_style
    set yui_style {
/*
Copyright (c) 2009, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.net/yui/license.txt
version: 2.7.0
*/
html{color:#000;background:#FFF;}body,div,dl,dt,dd,ul,ol,li,h1,h2,h3,h4,h5,h6,pre,code,form,fieldset,legend,input,button,textarea,p,blockquote,th,td{margin:0;padding:0;}table{border-collapse:collapse;border-spacing:0;}fieldset,img{border:0;}address,caption,cite,code,dfn,em,strong,th,var,optgroup{font-style:inherit;font-weight:inherit;}del,ins{text-decoration:none;}li{list-style:none;}caption,th{text-align:left;}h1,h2,h3,h4,h5,h6{font-size:100%;font-weight:normal;}q:before,q:after{content:'';}abbr,acronym{border:0;font-variant:normal;}sup{vertical-align:baseline;}sub{vertical-align:baseline;}legend{color:#000;}input,button,textarea,select,optgroup,option{font-family:inherit;font-size:inherit;font-style:inherit;font-weight:inherit;}input,button,textarea,select{*font-size:100%;}body{font:13px/1.231 arial,helvetica,clean,sans-serif;*font-size:small;*font:x-small;}select,input,button,textarea,button{font:99% arial,helvetica,clean,sans-serif;}table{font-size:inherit;font:100%;}pre,code,kbd,samp,tt{font-family:monospace;*font-size:108%;line-height:100%;}body{text-align:center;}#doc,#doc2,#doc3,#doc4,.yui-t1,.yui-t2,.yui-t3,.yui-t4,.yui-t5,.yui-t6,.yui-t7{margin:auto;text-align:left;width:57.69em;*width:56.25em;}#doc2{width:73.076em;*width:71.25em;}#doc3{margin:auto 10px;width:auto;}#doc4{width:74.923em;*width:73.05em;}.yui-b{position:relative;}.yui-b{_position:static;}#yui-main .yui-b{position:static;}#yui-main,.yui-g .yui-u .yui-g{width:100%;}.yui-t1 #yui-main,.yui-t2 #yui-main,.yui-t3 #yui-main{float:right;margin-left:-25em;}.yui-t4 #yui-main,.yui-t5 #yui-main,.yui-t6 #yui-main{float:left;margin-right:-25em;}.yui-t1 .yui-b{float:left;width:12.30769em;*width:12.00em;}.yui-t1 #yui-main .yui-b{margin-left:13.30769em;*margin-left:13.05em;}.yui-t2 .yui-b{float:left;width:13.8461em;*width:13.50em;}.yui-t2 #yui-main .yui-b{margin-left:14.8461em;*margin-left:14.55em;}.yui-t3 .yui-b{float:left;width:23.0769em;*width:22.50em;}.yui-t3 #yui-main .yui-b{margin-left:24.0769em;*margin-left:23.62em;}.yui-t4 .yui-b{float:right;width:13.8456em;*width:13.50em;}.yui-t4 #yui-main .yui-b{margin-right:14.8456em;*margin-right:14.55em;}.yui-t5 .yui-b{float:right;width:18.4615em;*width:18.00em;}.yui-t5 #yui-main .yui-b{margin-right:19.4615em;*margin-right:19.125em;}.yui-t6 .yui-b{float:right;width:23.0769em;*width:22.50em;}.yui-t6 #yui-main .yui-b{margin-right:24.0769em;*margin-right:23.62em;}.yui-t7 #yui-main .yui-b{display:block;margin:0 0 1em 0;}#yui-main .yui-b{float:none;width:auto;}.yui-gb .yui-u,.yui-g .yui-gb .yui-u,.yui-gb .yui-g,.yui-gb .yui-gb,.yui-gb .yui-gc,.yui-gb .yui-gd,.yui-gb .yui-ge,.yui-gb .yui-gf,.yui-gc .yui-u,.yui-gc .yui-g,.yui-gd .yui-u{float:left;}.yui-g .yui-u,.yui-g .yui-g,.yui-g .yui-gb,.yui-g .yui-gc,.yui-g .yui-gd,.yui-g .yui-ge,.yui-g .yui-gf,.yui-gc .yui-u,.yui-gd .yui-g,.yui-g .yui-gc .yui-u,.yui-ge .yui-u,.yui-ge .yui-g,.yui-gf .yui-g,.yui-gf .yui-u{float:right;}.yui-g div.first,.yui-gb div.first,.yui-gc div.first,.yui-gd div.first,.yui-ge div.first,.yui-gf div.first,.yui-g .yui-gc div.first,.yui-g .yui-ge div.first,.yui-gc div.first div.first{float:left;}.yui-g .yui-u,.yui-g .yui-g,.yui-g .yui-gb,.yui-g .yui-gc,.yui-g .yui-gd,.yui-g .yui-ge,.yui-g .yui-gf{width:49.1%;}.yui-gb .yui-u,.yui-g .yui-gb .yui-u,.yui-gb .yui-g,.yui-gb .yui-gb,.yui-gb .yui-gc,.yui-gb .yui-gd,.yui-gb .yui-ge,.yui-gb .yui-gf,.yui-gc .yui-u,.yui-gc .yui-g,.yui-gd .yui-u{width:32%;margin-left:1.99%;}.yui-gb .yui-u{*margin-left:1.9%;*width:31.9%;}.yui-gc div.first,.yui-gd .yui-u{width:66%;}.yui-gd div.first{width:32%;}.yui-ge div.first,.yui-gf .yui-u{width:74.2%;}.yui-ge .yui-u,.yui-gf div.first{width:24%;}.yui-g .yui-gb div.first,.yui-gb div.first,.yui-gc div.first,.yui-gd div.first{margin-left:0;}.yui-g .yui-g .yui-u,.yui-gb .yui-g .yui-u,.yui-gc .yui-g .yui-u,.yui-gd .yui-g .yui-u,.yui-ge .yui-g .yui-u,.yui-gf .yui-g .yui-u{width:49%;*width:48.1%;*margin-left:0;}.yui-g .yui-g .yui-u{width:48.1%;}.yui-g .yui-gb div.first,.yui-gb .yui-gb div.first{*margin-right:0;*width:32%;_width:31.7%;}.yui-g .yui-gc div.first,.yui-gd .yui-g{width:66%;}.yui-gb .yui-g div.first{*margin-right:4%;_margin-right:1.3%;}.yui-gb .yui-gc div.first,.yui-gb .yui-gd div.first{*margin-right:0;}.yui-gb .yui-gb .yui-u,.yui-gb .yui-gc .yui-u{*margin-left:1.8%;_margin-left:4%;}.yui-g .yui-gb .yui-u{_margin-left:1.0%;}.yui-gb .yui-gd .yui-u{*width:66%;_width:61.2%;}.yui-gb .yui-gd div.first{*width:31%;_width:29.5%;}.yui-g .yui-gc .yui-u,.yui-gb .yui-gc .yui-u{width:32%;_float:right;margin-right:0;_margin-left:0;}.yui-gb .yui-gc div.first{width:66%;*float:left;*margin-left:0;}.yui-gb .yui-ge .yui-u,.yui-gb .yui-gf .yui-u{margin:0;}.yui-gb .yui-gb .yui-u{_margin-left:.7%;}.yui-gb .yui-g div.first,.yui-gb .yui-gb div.first{*margin-left:0;}.yui-gc .yui-g .yui-u,.yui-gd .yui-g .yui-u{*width:48.1%;*margin-left:0;}.yui-gb .yui-gd div.first{width:32%;}.yui-g .yui-gd div.first{_width:29.9%;}.yui-ge .yui-g{width:24%;}.yui-gf .yui-g{width:74.2%;}.yui-gb .yui-ge div.yui-u,.yui-gb .yui-gf div.yui-u{float:right;}.yui-gb .yui-ge div.first,.yui-gb .yui-gf div.first{float:left;}.yui-gb .yui-ge .yui-u,.yui-gb .yui-gf div.first{*width:24%;_width:20%;}.yui-gb .yui-ge div.first,.yui-gb .yui-gf .yui-u{*width:73.5%;_width:65.5%;}.yui-ge div.first .yui-gd .yui-u{width:65%;}.yui-ge div.first .yui-gd div.first{width:32%;}#hd:after,#bd:after,#ft:after,.yui-g:after,.yui-gb:after,.yui-gc:after,.yui-gd:after,.yui-ge:after,.yui-gf:after{content:".";display:block;height:0;clear:both;visibility:hidden;}#hd,#bd,#ft,.yui-g,.yui-gb,.yui-gc,.yui-gd,.yui-ge,.yui-gf{zoom:1;}

body{margin:10px;}h1{font-size:138.5%;}h2{font-size:123.1%;}h3{font-size:108%;}h1,h2,h3{margin:1em 0;}h1,h2,h3,h4,h5,h6,strong,dt{font-weight:bold;}optgroup{font-weight:normal;}abbr,acronym{border-bottom:1px dotted #000;cursor:help;}em{font-style:italic;}del{text-decoration:line-through;}blockquote,ul,ol,dl{margin:1em;}ol,ul,dl{margin-left:2em;}ol li{list-style:decimal outside;}ul li{list-style:disc outside;}dl dd{margin-left:1em;}th,td{border:1px solid #000;padding:.5em;}th{font-weight:bold;text-align:center;}caption{margin-bottom:.5em;text-align:center;}sup{vertical-align:super;}sub{vertical-align:sub;}p,fieldset,table,pre{margin-bottom:1em;}button,input[type="checkbox"],input[type="radio"],input[type="reset"],input[type="submit"]{padding:1px;}
    }

    variable ruff_style
    set ruff_style {


/* Ruff default CSS */

h1,h2 {
  color: #888888;
  margin-bottom: 0.5em;
}

#ft {
    text-align: left;
    border-top: 1px solid #006666;
    color: #888888;
    margin-top: 10px;
}

.banner h2 {
    color: #006666;
}

#hd.banner {
 font-family: Trebuchet MS, Helvetica, sans-serif;
 font-weight: bold;
 font-size: 200%;
 line-height: 64px;
 border-bottom: thin solid #006666;
 color: #006666;
}


p.linkline {
    text-align: right;
    font-size: smaller;
/*    margin-top: -1em; */
    margin-bottom: 0;
}

#bd {
  font-family: Verdana;
  font-size: 108%;
}

.linkbox h2 {
  color: #177f75; /* #21b6a8; */
  margin-bottom: 0.2em;
  margin-top: 1.5em;
  font-size: 93%;
}

.linkbox {
  font-size: 93%;
}

.linkbox ul {
  margin-top: 0em;
  margin-left: 0.5em;
}

.linkbox ul li {
  list-style: none;
}

.linkbox a {
  color: #177f75;
  text-decoration: none;
}

.linkbox li a:hover {
  font-weight: bold;
}

div.navbox {
    /* margin-top: 1em; */
    color: #006666;
}

/* Note .navbox header css should be based on $header_levels */
.navbox h1, .navbox h2, .navbox h3, .navbox h4, .navbox h5 {
  font-size: 85%;
  margin: 0px;
}
.navbox h1, .navbox h2, .navbox h3 {
    font-weight: bold;
}
.navbox h1 {
    background-color: #006666;
}
.navbox h2 {
    margin-left: 1em;
}
.navbox h3 {
    margin-left: 2em;
}
.navbox h4 {
    margin-left: 2em;
    font-weight: normal;
}
.navbox h5 {
    margin-left: 3em;
    font-weight: normal;
}

.navbox hr {
    color: #006666;
}

.navbox a:link, .navbox a:visited {
  text-decoration: none;
    color: #006666;
}

.navbox a:hover {
   font-weight: bold;
}

.navbox h1 a:link, .navbox h1 a:visited {
    color: white;
}

/* Easy CSS Tooltip - by Koller Juergen [www.kollermedia.at] */
.navbox a:hover {background:#ffffff; text-decoration:none;} /*BG color is a must for IE6*/
.navbox a.tooltip span {display:none; padding:2px 3px; margin-left:8px; width: 100%;}
/* .navbox a.tooltip span {display:none; padding:2px 3px; margin-left:8px; width:130px;} */
.navbox a.tooltip:hover span{display:inline; position:absolute; border:1px solid #cccccc; background:#ffffff; color:#6c6c6c;}
.navbox h1 a:hover {background: #006666;}

span.ns_scope {
    color: #aaaaaa;
}

span.ns_scope a:link, span.ns_scope a:visited {
  text-decoration: none;
  color: #aaaaaa;

}

span.ns_scope a:hover {
  text-decoration: none;
  color: #666666;
}

table {
  margin: 1em;
  border: thin solid;
  border-collapse: collapse;
  border-color: #808080;
  padding: 4;
}

td {
  border: thin solid;
  border-color: #808080;
  vertical-align: top;
  font-size: 93%;
}
th {
  border: thin solid;
  border-color: #808080;
  padding: 4px;
  background-color: #CCCCCC;
}

dt, dd {
   font-size: 93%;
}

h1.ruff {
    background-color: #006666;
    color: #ffffff;
}
h2.ruff {
    font-variant: small-caps;
    color: #006666;
}

h3.ruff, h4.ruff, h5.ruff, h6.ruff {
    color: #006666;
}

h3.ruffclass, h3.ruffproc, h3.ruffmethod,
h4.ruffclass, h4.ruffproc, h4.ruffmethod,
h5.ruffclass, h5.ruffproc, h5.ruffmethod {
    border-bottom: thin solid #006666;
    color: #006666;
    margin-bottom: 0em;
}

pre.ruff {
    margin-top: 1em;
}

.ruff_synopsis {
    border: thin solid #cccccc;
    background: #eeeeee;
    font-size: smaller;
    font-family: "Courier New", Courier, monospace;
    padding: 5px;
    margin: 0px 50px 20px;
}
.ruff_const, .ruff_cmd, ruff_defitem {
    font-weight: bold;
    font-family: "Courier New", Courier, monospace;
}
.ruff_arg {
    font-style: italic;
    font-family: "Courier New", Courier, monospace;
}

.ruff_dyn_src {
    background-color: #eeeeee;
    padding: 5px;
    display: none;
}

    }
}

set ::ruff::formatter::html::javascript {
function toggleSource( id )
    {
        /* Copied from Rails */
        var elem
        var link

        if( document.getElementById )
        {
            elem = document.getElementById( id )
            link = document.getElementById( "l_" + id )
        }
        else if ( document.all )
        {
            elem = eval( "document.all." + id )
            link = eval( "document.all.l_" + id )
        }
        else
        return false;

        if( elem.style.display == "block" )
        {
            elem.style.display = "none"
            link.innerHTML = "Show source"
        }
        else
        {
            elem.style.display = "block"
            link.innerHTML = "Hide source"
        }
    }
}

# Credits: tcllib/Caius markdown module
proc ::ruff::formatter::html::md_inline {text {scope {}}} {

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
                                append result "<em>[md_inline $sub $scope]</em>"
                            }
                            2 {
                                append result "<strong>[md_inline $sub $scope]</strong>"
                            }
                            3 {
                                append result "<strong><em>[md_inline $sub $scope]</em></strong>"
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

                    append result "<code>[escape $sub]</code>"
                    set index [expr [lindex $m 1] + 1]
                    continue
                }
            }
            {!} -
            {[} {
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

                    set url [escape [string trim $url {<> }]]
                    set txt [md_inline $txt $scope]
                    set title [md_inline $title $scope]

                    set match_found 1
                } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                    if {$lbl eq {}} {
                        set lbl [regsub -all {\s+} $txt { }]
                    }

                    set code_link [_resolve_code_link $lbl $scope]
                    if {[llength $code_link]} {
                        lassign $code_link url txt css
                        set url [escape $url]
                        set txt [escape $txt]
                        set title $txt

                        # RUFF CODE REFERENCE
                        incr index [string length $m]
                        set match_found 1
                    } else {
                        set lbl [string tolower $lbl]

                        if {[info exists ::Markdown::_references($lbl)]} {
                            lassign $::Markdown::_references($lbl) url title

                            set url [escape [string trim $url {<> }]]
                            set txt [md_inline $txt $scope]
                            set title [md_inline $title $scope]

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
                        set link [escape $link]
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

                set chr [escape $chr]
            }
            {&} {
                # ENTITIES
                if {[regexp -start $index $re_entity $text m]} {
                    append result $m
                    incr index [string length $m]
                    continue
                }

                set chr [escape $chr]
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
                set chr [escape $chr]
            }
            default {}
        }

        append result $chr
        incr index
    }
 
    return $result
}

proc ruff::formatter::html::escape {s} {
    # s - string to be escaped
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

proc ruff::formatter::html::symbol_link {sym {scope {}}} {
    return [md_inline [symbol_ref $sym] $scope]
}

proc ::ruff::formatter::html::fmtpreformatted {content} {
    return "<pre class='ruff'>\n[escape $content]\n</pre>\n"
}

proc ::ruff::formatter::html::_resolve_code_link {link_label scope} {
    # Locates the target of a link.
    # link_label - the potential link to be located, for example the name
    #  of a proc.
    # scope - the namespace path to search to locate a target
    #
    # Returns a list consisting of the url, text and the CSS class to use.
    # An empty list is returned if the link_label does not match a code element.
    variable link_targets

    set css "class='ruff_cmd'"

    # If the label falls within the specified scope, we will hide the scope
    # in the displayed label. The label may fall within the scope either
    # as a namespace (::) or a class member (.)

    # First check if this link itself is directly present
    if {[info exists link_targets($link_label)]} {
        return [list "$link_targets($link_label)" [trim_namespace $link_label $scope] $css]
    }

    # Only search scope if not fully qualified
    if {! [string match ::* $link_label]} {
        while {$scope ne ""} {
            # Check class (.) and namespace scope (::)
            foreach sep {. ::} {
                set qualified ${scope}${sep}$link_label
                if {[info exists link_targets($qualified)]} {
                    return [list "$link_targets($qualified)" [trim_namespace $link_label $scope] $css]
                }
            }
            set scope [namespace qualifiers $scope]
        }
    }

    return [list ]
}

proc ruff::formatter::html::anchor args {
    # Given a list of strings, constructs an anchor from them
    # and returns it. It is already HTML-escaped. Empty arguments
    # are ignored
    set parts {}
    foreach arg $args {
        if {$arg ne ""} {
            lappend parts $arg
        }
    }

    return [regsub -all {[^-:\w_.]} [join $parts -] _]
}

proc ruff::formatter::html::ns_link {ns name} {
    if {$ns eq "::" && $name eq ""} {
        return [ns_file_base $ns]
    } else {
        return "[ns_file_base $ns]#[anchor $name]"
    }
}

proc ruff::formatter::html::fmtdeflist {listitems args} {

    # -preformatted is one of both, none, itemname or itemdef
    array set opts {
        -preformatted itemname
        -scope {}
    }
    array set opts $args

    append doc "<table class='ruff_deflist'>\n"
    foreach {name desc} $listitems {
        if {$opts(-preformatted) in {none itemname}} {
            set desc [md_inline $desc $opts(-scope)]
        }
        if {$opts(-preformatted) in {none itemdef}} {
            set name [md_inline $name $opts(-scope)]
        }
        append doc "<tr><td class='ruff_defitem'>$name</td><td class='ruff_defitem'>$desc</td></tr>\n"
    }
    append doc "</table>\n"
    
    return $doc
}

proc ruff::formatter::html::fmtbulletlist {listitems {scope {}}} {
    append doc "<ul class='ruff'>\n"
    foreach item $listitems {
        append doc "<li>[md_inline $item $scope]</li>\n"
    }
    append doc "</ul>\n"
    return $doc
}


proc ruff::formatter::html::fmtprochead {name args} {
    # Procedure for formatting proc, class and method headings
    variable navlinks
    variable link_targets

    set opts(-level) 3
    set opts(-cssclass) "ruff"
    array set opts $args

    set ns [namespace qualifiers $name]
    set anchor [anchor $name]
    set linkinfo [dict create tag h$opts(-level) href "#$anchor"]
    if {[info exists opts(-tooltip)]} {
        dict set linkinfo tip [escape $opts(-tooltip)]
    }
    dict set linkinfo label [namespace tail $name]
    dict set navlinks $anchor $linkinfo
    if {[string length $ns]} {
        set ns_link [symbol_link $ns]
        set doc "<h$opts(-level) class='$opts(-cssclass)'><a name='$anchor'>[escape [namespace tail $name]]</a><span class='ns_scope'> \[${ns_link}\]</span></h$opts(-level)>\n"
    } else {
        set doc "<h$opts(-level) class='$opts(-cssclass)'><a name='$anchor'>[escape $name]</a></h$opts(-level)>\n"
    }

    # Include a link to top of class/namespace if possible.

    if {[info exists link_targets($ns)]} {
        set linkline "<a href='$link_targets($ns)'>[namespace tail $ns]</a>, "
    }
    if {[program_option -singlepage]} {
        append linkline "<a href='#_top'>Top</a>"
    } else {
        append linkline "<a href='[ns_link :: {}]'>Top</a>"
    }
    return "${doc}\n<p class='linkline'>$linkline</p>"
}

proc ruff::formatter::html::fmthead {text level args} {
    variable navlinks

    set opts(-link) [expr {$level > 4 ? false : true}]
    set opts(-scope) "";    # -scope allows context for headings
    array set opts $args

    if {$opts(-link)} {
        set anchor [anchor $opts(-scope) $text]
        set linkinfo [dict create tag h$level href "#$anchor"]
        if {[info exists opts(-tooltip)]} {
            dict set linkinfo tip [escape $opts(-tooltip)]
        }
        dict set linkinfo label $text
        dict set navlinks $anchor $linkinfo
        return "<h$level class='ruff'><a name='$anchor'>[escape $text]</a></h$level>\n"
    } else {
        return "<h$level class='ruff'>[escape $text]</h$level>\n"
    }
}

proc ruff::formatter::html::fmtpara {text {scope {}}} {
    return "<p class='ruff'>[md_inline [string trim $text] $scope]</p>\n"
}

proc ruff::formatter::html::fmtparas {paras {scope {}}} {
    # Given a list of paragraph elements, returns
    # them appropriately formatted for html output.
    # paras - a flat list of pairs with the first element
    #  in a pair being the type, and the second the content
    #
    set doc ""
    foreach {type content} $paras {
        switch -exact -- $type {
            header {
                lassign $content level text
                append doc [fmthead $text $level -scope $scope]
            }
            paragraph {
                append doc [fmtpara $content $scope]
            }
            deflist {
                append doc [fmtdeflist $content -preformatted none -scope $scope]
            }
            bulletlist {
                append doc [fmtbulletlist $content $scope]
            }
            preformatted {
                append doc [fmtpreformatted $content]
            }
            default {
                error "Unknown paragraph element type '$type'."
            }
        }
    }
    return $doc
}

proc ruff::formatter::html::generate_proc_or_method {procinfo args} {
    # Formats the documentation for a proc in HTML format
    # procinfo - proc or method information in the format returned
    #   by extract_proc or extract_ooclass
    #
    # The following options may be specified:
    #   -includesource BOOLEAN - if true, the source code of the
    #     procedure is also included. Default value is false.
    #   -hidenamespace NAMESPACE - if specified as non-empty,
    #    program element names beginning with NAMESPACE are shown
    #    with that namespace component removed.
    #   -skipsections SECTIONLIST - a list of sections to be left
    #    out from the generated document. This is generally useful
    #    if the return value is to be included as part of a larger
    #    section (e.g. constructor within a class)
    #
    # Returns the proc documentation as a HTML formatted string.

    variable header_levels
    variable header_css

    array set opts {
        -includesource false
        -hidenamespace ""
        -skipsections {}
    }
    array set opts $args

    array set aproc $procinfo

    if {$aproc(proctype) ne "method"} {
        set scope [namespace qualifiers $aproc(name)]
    } else {
        set scope $aproc(class); # Scope is name of class
    }

    set doc "";                 # Document string

    set header_title [trim_namespace $aproc(name) $opts(-hidenamespace)]
    set proc_name [trim_namespace $aproc(name) $opts(-hidenamespace)]

    # Construct the synopsis and simultaneously the parameter descriptions
    # These are constructed as HTML (ie. already escaped) since we want
    # to format parameters etc.
    set desclist {};            # For the parameter descriptions
    set arglist {};             # Used later for synopsis
    foreach param $aproc(parameters) {
        set name [dict get $param name]
        set desc {}
        if {[dict get $param type] eq "parameter"} {
            lappend arglist [_arg $name]
            if {[dict exists $param default]} {
                lappend desc "(optional, default [_const [dict get $param default]])"
            }
        }
        if {[dict exists $param description]} {
            lappend desc [md_inline [dict get $param description] $scope]
        } elseif {$name eq "args"} {
            lappend desc "Additional options."
        }
 
        lappend desclist [_arg $name] [join $desc " "]
    }

    if {$aproc(proctype) ne "method"} {
        set synopsis "[_cmd [namespace tail $proc_name]] [join $arglist { }]"
    } else {
        switch -exact -- $aproc(name) {
            constructor {set synopsis "[_cmd $aproc(class)] [_cmd create] [join $arglist { }]"}
            destructor  {set synopsis "[_arg OBJECT] [_cmd destroy]"}
            default  {set synopsis "[_arg OBJECT] [_cmd [namespace tail $aproc(name)]] [join $arglist { }]"}
        }
    }

    if {[info exists aproc(summary)] && $aproc(summary) ne ""} {
        set summary $aproc(summary)
    } elseif {[info exists aproc(return)] && $aproc(return) ne ""} {
        set summary $aproc(return)
    }

    if {[lsearch -exact $opts(-skipsections) header] < 0} {
        # We need a fully qualified name for cross-linking purposes
        if {$aproc(proctype) eq "method"} {
            set fqn $aproc(class)::$aproc(name)
        } else {
            set fqn $aproc(name)
        }

        if {[info exists summary]} {
            append doc [fmtprochead $fqn -tooltip $summary -level $header_levels($aproc(proctype)) -cssclass $header_css($aproc(proctype))]
        } else {
            append doc [fmtprochead $fqn -level $header_levels($aproc(proctype)) -cssclass $header_css($aproc(proctype))]
        }
    }

    if {[info exists summary]} {
        append doc [fmtpara $summary $scope]
    }

    append doc "<p><div class='ruff_synopsis'>$synopsis</div></p>\n"

    if {[llength $desclist]} {
        append doc [fmthead Parameters $header_levels(nonav)]
        # Parameters are output as a list.
        append doc [fmtdeflist $desclist -preformatted both]
    }

    if {[info exists aproc(return)] && $aproc(return) ne ""} {
        append doc [fmthead "Return value" $header_levels(nonav)]
        append doc [fmtpara $aproc(return) $scope]
    }

    # Loop through all the paragraphs. Note the first para is also 
    # the summary (already output) but we will show that in the general
    # description as well.
    if {[llength $aproc(description)]} {
        append doc [fmthead "Description" $header_levels(nonav)]
        append doc [fmtparas $aproc(description) $scope]
    }

    # Do we include the source code in the documentation?
    if {$opts(-includesource)} {
        set src_id [_new_srcid]
        if {[info exists aproc(ensemble)]} {
            set note "<em style='font-size:small;'># NOTE: showing source of procedure implementing ensemble subcommand.</em>"
        } else {
            set note ""
        }
        append doc "<div class='ruff_source'>"
        append doc "<p class='ruff_source_link'>"
        append doc "<a id='l_$src_id' href=\"javascript:toggleSource('$src_id')\">Show source</a>"
        append doc "</p>\n"
        append doc "<div id='$src_id' class='ruff_dyn_src'>$note\n<pre>\n[escape $aproc(source)]\n</pre></div>\n"
        append doc "</div>";    # class='ruff_source'
    }


    return "${doc}\n"
}

proc ruff::formatter::html::generate_ooclass {classinfo args} {

    # Formats the documentation for a class in HTML format
    # classinfo - class information in the format returned
    #   by extract_ooclass
    # -includesource BOOLEAN - if true, the source code of the
    #   procedure is also included. Default value is false.
    # -hidenamespace NAMESPACE - if specified as non-empty,
    #  program element names beginning with NAMESPACE are shown
    #  with that namespace component removed.
    #
    # Returns the class documentation as a HTML formatted string.

    variable header_levels
    variable header_css

    array set opts {
        -includesource false
        -hidenamespace ""
        -mergeconstructor false
    }
    array set opts $args

    array set aclass $classinfo
    set class_name [trim_namespace $aclass(name) $opts(-hidenamespace)]
    set scope [namespace qualifiers $aclass(name)]

    array set method_summaries {}

    # We want to put the class summary right after the header but cannot
    # generate it till the end so we put the header in a separate variable
    # to be merged at the end.
    append dochdr [fmtprochead $aclass(name) -level $header_levels(class) -cssclass $header_css(class)]

    set doc ""
    # Include constructor in main class definition
    if {$opts(-mergeconstructor) && [info exists aclass(constructor)]} {
        error "-mergeconstructor not implemented"
        TBD
        append doc [generate_proc_or_method $aclass(constructor) \
                        -includesource $opts(-includesource) \
                        -hidenamespace $opts(-hidenamespace) \
                        -skipsections [list header name] \
                       ]
    }

    if {[llength $aclass(superclasses)]} {
        append doc [fmthead Superclasses $header_levels(nonav)]
        # NOTE: Don't sort - order matters! 
        set class_links [symbol_refs_string [trim_namespace_multi $aclass(superclasses) $opts(-hidenamespace)]]
        append doc [fmtpara $class_links $scope]
    }
    if {[llength $aclass(mixins)]} {
        append doc [fmthead "Mixins" $header_levels(nonav)]

        # Don't sort - order matters!
        set class_links [symbol_refs_string [trim_namespace_multi $aclass(mixins) $opts(-hidenamespace)]]
        append doc [fmtpara $class_links $scope]
    }

    if {[llength $aclass(subclasses)]} {
        append doc [fmthead "Subclasses" $header_levels(nonav)]
        set class_links [symbol_refs_string [trim_namespace_multi $aclass(subclasses) $opts(-hidenamespace)]]
        append doc [fmtpara $class_links $scope]
    }

    # Inherited and derived methods are listed as such.
    if {[llength $aclass(external_methods)]} {
        array set external_methods {}
        foreach external_method $aclass(external_methods) {
            # Qualify the name with the name of the implenting class
            foreach {name imp_class} $external_method break
            if {$imp_class ne ""} {
                set imp_class [trim_namespace_multi $imp_class $opts(-hidenamespace)]
            }
            lappend external_methods($imp_class) ${imp_class}.$name
            set method_summaries($name) [dict create label [escape $name] desc [md_inline "See [symbol_ref ${imp_class}.$name]" $scope]]
        }
        append doc [fmthead "Inherited and mixed-in methods" $header_levels(nonav)]
        # Construct a sorted list based on inherit/mixin class name
        set ext_list {}
        foreach imp_class [lsort -dictionary [array names external_methods]] {
            set refs [symbol_refs_string $external_methods($imp_class)]
            lappend ext_list \
                [md_inline [symbol_ref $imp_class] $scope] \
                [md_inline $refs $imp_class]
        }
        append doc [fmtdeflist $ext_list -preformatted both]
    }
    if {[llength $aclass(filters)]} {
        append doc [fmthead "Filters" $header_levels(nonav)]
        append doc [fmtpara [join [lsort $aclass(filters)] {, }] $scope]
    }

    if {[info exists aclass(constructor)] && !$opts(-mergeconstructor)} {
        set method_summaries($aclass(name).constructor) \
            [dict create label \
                 [symbol_link $aclass(name).constructor $aclass(name)] \
                 desc \
                 "Constructor for the class" ]
        append doc [generate_proc_or_method $aclass(constructor) \
                        -includesource $opts(-includesource) \
                        -hidenamespace $opts(-hidenamespace) \
                       ]
    }
    if {[info exists aclass(destructor)]} {
        set method_summaries($aclass(name).destructor) [dict create label [symbol_link $aclass(name).destructor $aclass(name)] desc "Destructor for the class" ]
        append doc [generate_proc_or_method $aclass(destructor) \
                        -includesource $opts(-includesource) \
                        -hidenamespace $opts(-hidenamespace) \
                        ]
    }

    # We want methods and forwarded methods listed together and sorted
    array set methods {}
    foreach methodinfo $aclass(methods) {
        set methods([dict get $methodinfo name]) [list method $methodinfo]
    }
    if {[info exists aclass(forwards)]} {
        foreach forwardinfo $aclass(forwards) {
            set methods([dict get $forwardinfo name]) [list forward $forwardinfo]
        }
    }

    foreach name [lsort [array names methods]] {
        foreach {type info} $methods($name) break
        if {$type eq "method"} {
            append doc [generate_proc_or_method $info \
                            -includesource $opts(-includesource) \
                            -hidenamespace $opts(-hidenamespace) \
                           ]
            if {[dict exists $info summary]} {
                set summary [escape [dict get $info summary]]
            } elseif {[dict exists $info return]} {
                set summary [escape [dict get $info return]]
            } else {
                set summary ""
            }
            set method_summaries($aclass(name).$name) \
                [dict create label \
                     [symbol_link $aclass(name).$name $aclass(name)] \
                     desc \
                     $summary]
        } else {
            set forward_text "Method forwarded to [dict get $info forward]"
            append doc [fmtprochead $aclass(name)::$name -tooltip $forward_text -level $header_levels(method) -cssclass $header_css(method)]
            append doc [fmtpara $forward_text $scope]
            set method_summaries($aclass(name).$name) \
                [dict create label \
                     [symbol_link $aclass(name).$name $aclass(name)] \
                     desc \
                     [md_inline $forward_text $scope]]
        }
    }

    set summary_list {}
    foreach name [lsort -dictionary [array names method_summaries]] {
        lappend summary_list [dict get $method_summaries($name) label] [dict get $method_summaries($name) desc]
    }
    if {[llength $summary_list]} {
        # append dochdr [fmthead "Method summary" $header_levels(nonav)]
        append dochdr [fmtdeflist $summary_list -preformatted both]
    }

    return "$dochdr\n$doc"
}

proc ::ruff::formatter::html::generate_ooclasses {classinfodict args} {
    # Given a list of class information elements returns as string
    # containing class documentation formatted for NaturalDocs
    # classinfodict - dictionary keyed by class name and each element
    #   of which is in the format returned by extract_ooclass
    #
    # Additional parameters are passed on to the generate_ooclass procedure.

    set doc ""
    foreach name [lsort [dict keys $classinfodict]] {
        append doc \
            [generate_ooclass [dict get $classinfodict $name] {*}$args]
        append doc "\n\n"
    }

    return $doc
}
    
proc ::ruff::formatter::html::generate_procs {procinfodict args} {
    # Given a dictionary of proc information elements returns a string
    # containing HTML format documentation.
    # procinfodict - dictionary keyed by name of the proc with the associated
    #   value being in the format returned by extract_proc
    #
    # Additional parameters are passed on to the generate_proc procedure.
    #
    # Returns documentation string in NaturalDocs format with 
    # procedure descriptions sorted in alphabetical order
    # within each namespace.

    set doc ""
    set namespaces [sift_names [dict keys $procinfodict]]
    foreach ns [lsort -dictionary [dict keys $namespaces]] {
        foreach name [lsort -dictionary [dict get $namespaces $ns]] {
            append doc \
                [generate_proc_or_method [dict get $procinfodict $name] {*}$args]\n\n
        }
    }

    return $doc
}
    

proc ::ruff::formatter::html::generate_document {classprocinfodict args} {
    # Produces documentation in HTML format from the passed in
    # class and proc metainformation.
    #   classprocinfodict - dictionary containing meta information about the 
    #    classes and procs
    # The following options may be specified:
    #   -preamble DICT - a dictionary indexed by a namespace. Each value is
    #    a flat list of pairs consisting of a heading and
    #    corresponding content. These are inserted into the document
    #    before the actual class and command descriptions for a namespace.
    #    The key "::" corresponds to documentation to be printed at
    #    the very beginning.
    #   -includesource BOOLEAN - if true, the source code of the
    #     procedure is also included. Default value is false.
    #   -hidenamespace NAMESPACE - if specified as non-empty,
    #    program element names beginning with NAMESPACE are shown
    #    with that namespace component removed.
    #   -singlepage BOOLEAN - if `true` (default) files are written
    #    as a single page. Else each namespace is written to a separate file.
    #   -titledesc STRING - the title for the documentation.
    #    Used as the title for the document.
    #    If undefined, the string "Reference" is used.
    #   -stylesheet URLLIST - if specified, the stylesheets passed in URLLIST
    #    are used instead of the built-in styles. Note the built-in YUI is always
    #    included.

    variable yui_style;         # Contains default YUI based layout
    variable ruff_style;        # Contains default Ruff style sheet
    variable javascript;        # Javascript used by the page
    variable navlinks;          # Links generated for navigation menu
    variable link_targets;    # Links for cross-reference purposes

    # Re-initialize in case of multiple invocations
    array unset link_targets
    array set link_targets {}
    set navlinks [dict create]

    array set opts \
        [list \
             -includesource false \
             -hidenamespace "" \
             -outdir "." \
             -singlepage true \
             -titledesc "" \
             -modulename "Reference" \
             ]

    array set opts $args

    # First collect all "important" names so as to build a list of
    # linkable targets. These will be used for cross-referencing and
    # also to generate links correctly in the case of
    # duplicate names in different namespaces or classes.
    #
    # A class name is also treated as a namespace component
    # although that is not strictly true.
    foreach {class_name class_info} [dict get $classprocinfodict classes] {
        set ns [namespace qualifiers $class_name]
        set link_targets($class_name) [ns_link $ns $class_name]
        set method_info_list [concat [dict get $class_info methods] [dict get $class_info forwards]]
        foreach name {constructor destructor} {
            if {[dict exists $class_info $name]} {
                lappend method_info_list [dict get $class_info $name]
            }
        }
        foreach method_info $method_info_list {
            # The class name is the scope for methods. Because of how
            # the link target lookup works, we use the namespace
            # operator to separate the class from method. We also
            # store it a second time using the "." separator as that
            # is how they are sometimes referenced.
            set method_name [dict get $method_info name]
            set link_targets(${class_name}::${method_name}) [ns_link $ns ${class_name}::${method_name}]
            set link_targets(${class_name}.${method_name}) $link_targets(${class_name}::${method_name}) 
        }
    }
    foreach proc_name [dict keys [dict get $classprocinfodict procs]] {
        fqn! $proc_name
        set link_targets(${proc_name}) [ns_link [namespace qualifiers $proc_name] $proc_name]
    }

    if {0} {
        Was used for autolinking. Not used any more.
        # Build a regexp that can be used to convert references to classes, methods
        # and procedures to links. 
        set methods {}
        foreach {class_name class_info} [dict get $classprocinfodict classes] {
            # Note we add both forms of method qualification - using :: and . -
            # since comments might be use both forms.
            foreach name {constructor destructor} {
                if {[dict exists $class_info $name]} {
                    lappend methods ${class_name}.$name ${class_name}::$name
                }
            }
            foreach method_info [dict get $class_info methods] {
                lappend methods ${class_name}.[dict get $method_info name] ${class_name}::[dict get $method_info name]
            }
            foreach method_info [dict get $class_info forwards] {
                lappend methods ${class_name}.[dict get $method_info name] ${class_name}::[dict get $method_info name]
            }
        }
        set ref_regexp [build_symbol_regexp \
                            [concat \
                                [dict keys [dict get $classprocinfodict procs]] \
                                [dict keys [dict get $classprocinfodict classes]] \
                                $methods
                                ]
                      ]
    }

    # Generate the header used by all files
    set header {<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">}
    append header "<html><head><title>$opts(-titledesc)</title>\n"
    if {[info exists opts(-stylesheets)]} {
        append header "<style>\n$yui_style\n</style>\n"
        foreach url $opts(-stylesheets) {
            append header "<link rel='stylesheet' type='text/css' href='$url' />"
        }
    } else {
        # Use built-in styles
        append header "<style>\n$yui_style\n$ruff_style\n</style>\n"
    }
    append header "<script>$javascript</script>"
    append header "</head>\n<body>"

    # YUI stylesheet templates
    append header "<div id='doc3' class='yui-t2'>"
    if {$opts(-titledesc) ne ""} {
        append header "<div id='hd' class='banner'>\n<a style='text-decoration:none;' href='[ns_link :: {}]'>$opts(-titledesc)</a>\n</div>\n"
    }
    append header "<div id='bd'>"

    if {$opts(-modulename) ne ""} {
        append header [fmthead $opts(-modulename) 1 -link 0]
    }

    # Generate the footer used by all files
    append footer "</div>";        # <div id='bd'>
    append footer "<div id='ft'>"
    append footer "<div style='float: right;'>Document generated by Ruff!</div>"
    if {[info exists opts(-copyright)]} {
        append footer "<div>&copy; [escape $opts(-copyright)]</div>"
    }
    append footer "</div>\n"
    append footer "</div>";        # <div id='doc3' ...>
    append footer "</body></html>"


    # Arrange procs and classes by namespace
    set info_by_ns [sift_classprocinfo $classprocinfodict]

    # Collect links to namespaces. Need to do this before generating preamble
    foreach ns [dict keys $info_by_ns] {
        set link_targets($ns) [ns_link $ns $ns]
    }

    # Now generate documentation in one of two modes: single page or separate.
    set docs [list ]

    # Generate the main page. Further sections will be either appended to
    # it or generated separately.
    set doc $header
    append doc "<div id='yui-main'><div class='yui-b'><a name='_top'></a>"

    if {[info exists opts(-preamble)] &&
        [dict exists $opts(-preamble) ""]} {
        # Print the toplevel (global stuff)
        foreach paras [dict get $opts(-preamble) ""] {
            append doc [fmtparas $paras]
        }
    } else {
        # If no preamble was given and we are in multipage mode
        # display a generic message.
        append doc [md_inline "Please follow the links on the left for documentation of individual modules."]
    }

    # If not single page, append links to namespace pages and close page
    if {!$opts(-singlepage)} {
        append doc "</div></div>";        # <div class='yui-b'><div id=yui-main>
        # Add the navigation bits
        set nav_common ""
        foreach ns [lsort [dict keys $info_by_ns]] {
            append nav_common "<h1><a href='[ns_file_base $ns]'>$ns</a></h1>"
        }
        append doc "<div class='yui-b navbox'>$nav_common</div>"
        append doc $footer
        lappend docs "::" $doc
    }

    foreach ns [lsort [dict keys $info_by_ns]] {
        if {!$opts(-singlepage)} {
            set doc $header
            append doc "<div id='yui-main'><div class='yui-b'><a name='_top'></a>"
        }

        append doc [fmthead $ns 1]
 
        if {[info exists opts(-preamble)] &&
            [dict exists $opts(-preamble) $ns]} {
            # Print the preamble for this namespace
            append doc [fmtparas [dict get $opts(-preamble) $ns] $ns]
        }

        if {[dict exists $info_by_ns $ns procs]} {
            append doc [fmthead "Commands" 2 -scope $ns]
            append doc [generate_procs [dict get $info_by_ns $ns procs] \
                            -includesource $opts(-includesource) \
                            -hidenamespace $opts(-hidenamespace) \
                           ]
        }

        if {[dict exists $info_by_ns $ns classes]} {
            append doc [fmthead "Classes" 2 -scope $ns]
            append doc [generate_ooclasses [dict get $info_by_ns $ns classes] \
                            -includesource $opts(-includesource) \
                            -hidenamespace $opts(-hidenamespace) \
                           ]
        }
        if {! $opts(-singlepage)} {
            append doc "</div></div>";        # <div class='yui-b'><div id=yui-main>
            # Add the navigation bits
            append doc "<div class='yui-b navbox'>"
            # First the toplevel links
            append doc $nav_common
            append doc "<hr>"
            # Then the navlinks for this namespace
            dict for {text link} $navlinks {
                set label [escape [dict get $link label]]
                set tag  [dict get $link tag]
                set href [dict get $link href]
                if {[dict exists $link tip]} {
                    append doc "<$tag><a class='tooltip' href='$href'>$label<span>[dict get $link tip]</span></a></$tag>"
                } else {
                    append doc "<$tag><a href='$href'>$label</a></$tag>"
                }
            }
            append doc "</div>";        # <div class='yui-b navbox'>
            append doc $footer
            lappend docs $ns $doc

            # Reset navigation links for nxt page
            set navlinks [dict create]
        }
    }
    if {$opts(-singlepage)} {
        append doc "</div></div>";        # <div class='yui-b'><div id=yui-main>

        # Add the navigation bits
        append doc "<div class='yui-b navbox'>"
        dict for {text link} $navlinks {
            set label [escape [dict get $link label]]
            set tag  [dict get $link tag]
            set href [dict get $link href]
            if {[dict exists $link tip]} {
                append doc "<$tag><a class='tooltip' href='$href'>$label<span>[dict get $link tip]</span></a></$tag>"
            } else {
                append doc "<$tag><a href='$href'>$label</a></$tag>"
            }
        }
        append doc "</div>";        # <div class='yui-b navbox'>
        append doc $footer
        lappend docs "::" $doc
    }
        
    return $docs
}

proc ::ruff::formatter::html::_const {text} {
    return "<span class='ruff_const'>[escape $text]</span>"
}

proc ::ruff::formatter::html::_cmd {text} {
    return "<span class='ruff_cmd'>[escape $text]</span>"
}

proc ::ruff::formatter::html::_arg {text} {
    return "<span class='ruff_arg'>[escape $text]</span>"
}

proc ::ruff::formatter::html::_new_srcid {} {
    variable src_id_ctr
    if {![info exists src_id_ctr]} {
        set src_id_ctr 0
    }
    return [incr src_id_ctr]
}
