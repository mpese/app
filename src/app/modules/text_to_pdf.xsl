<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:mpese="http://mpese.ac.uk"
                exclude-result-prefixes="xs"
                version="2.0">

    <xsl:import href="mpese-common.xsl"/>

    <!-- parameter is passed in by the transformer -->
    <xsl:param name="url" />

    <!-- font and sizes -->
    <xsl:variable name="font">Times</xsl:variable>
    <xsl:variable name="subheading-size">14pt</xsl:variable>
    <xsl:variable name="text-size">12pt</xsl:variable>
    <xsl:variable name="list-size">11pt</xsl:variable>
    <xsl:variable name="note-size">10pt</xsl:variable>

    <!-- ===== NAMED TEMPLATES ===== -->

    <!-- title of the document -->
    <xsl:template name="title">
        <xsl:variable name="title">
            <xsl:choose>
                <xsl:when test="normalize-space(//tei:fileDesc/tei:titleStmt/tei:title) eq ''">Untitled</xsl:when>
                <xsl:otherwise><xsl:value-of select="//tei:fileDesc/tei:titleStmt/tei:title"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="date">
            <xsl:choose>
                <xsl:when test="normalize-space(//tei:profileDesc/tei:creation/tei:date) eq ''">No date</xsl:when>
                <xsl:otherwise><xsl:value-of select="//tei:profileDesc/tei:creation/tei:date/string()"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <fo:block font-family="{$font}" font-size="16pt" text-align="center" font-weight="bold">
            <xsl:value-of select="$title"/><xsl:text> </xsl:text>(<xsl:value-of select="$date"/>)
        </fo:block>
    </xsl:template>

    <!-- author -->
    <xsl:template name="author">
        <fo:block font-family="{$font}" font-size="12pt" text-align="center">
            <xsl:for-each select="//tei:fileDesc/tei:titleStmt/tei:author">
                <xsl:value-of select="tei:persName"/>
            </xsl:for-each>
        </fo:block>
    </xsl:template>

    <!-- manuscript -->
    <xsl:variable name="ms">
        <xsl:variable name="repo">
            <xsl:value-of select="//tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:repository"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="//tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:collection"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="//tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno"/>
        </xsl:variable>
        <xsl:variable name="folios" select="//tei:pb/@n/string()"/>
        <xsl:variable name="folio_label">
            <xsl:choose>
                <xsl:when test="count($folios) &gt; 1">
                    <xsl:text>, ff. </xsl:text>
                    <xsl:value-of select="$folios[1]"/>
                    <xsl:text>–</xsl:text>
                    <xsl:value-of select="$folios[last()]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>, f. </xsl:text>
                    <xsl:value-of select="$folios"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$repo"/> <xsl:value-of select="$folio_label"/>
    </xsl:variable>

    <!-- Introduction to the text -->
    <xsl:template name="introduction">
        <!-- subtitle -->
        <fo:block font-family="{$font}" font-size="{$subheading-size}" font-weight="bold"
                  space-before="12pt" space-after="6pt">Introduction</fo:block>
        <!-- text within the abstract -->
        <xsl:apply-templates select="//tei:profileDesc/tei:abstract"/>
    </xsl:template>

    <!-- Transcript of the text -->
    <xsl:template name="transcript">
        <!-- subtitle -->
        <fo:block font-family="{$font}" font-size="{$subheading-size}" font-weight="bold"
                  space-before="12pt" space-after="6pt">Transcript</fo:block>
        <!-- text within the abstract -->
        <fo:block font-family="{$font}" font-size="10pt" text-align="left"><xsl:value-of select="$ms"/></fo:block>
        <xsl:apply-templates select="//tei:text/tei:body"/>
    </xsl:template>

    <!-- Manuscript witnesses -->
    <xsl:template name="mss_witness">
        <!-- subtitle -->
        <fo:block font-family="{$font}" font-size="{$subheading-size}" font-weight="bold"
                  space-before="12pt" space-after="6pt">Other manuscript witnesses</fo:block>
        <!-- witness list -->
         <xsl:apply-templates select="//tei:sourceDesc/tei:listBibl[@xml:id='mss_witness_generated']"/>
    </xsl:template>

    <!-- 17th century print witnesses -->
    <xsl:template name="C17_print_witness">
        <!-- subtitle -->
        <fo:block font-family="{$font}" font-size="{$subheading-size}" font-weight="bold"
                  space-before="12pt" space-after="6pt">Seventeenth-century print exemplars</fo:block>
        <!-- witness list -->
         <xsl:apply-templates select="//tei:sourceDesc/tei:listBibl[@xml:id='C17_print_witness']"/>
    </xsl:template>

    <!-- 17th century print witnesses -->
    <xsl:template name="modern_print_witness">
        <!-- subtitle -->
        <fo:block font-family="{$font}" font-size="{$subheading-size}" font-weight="bold"
                  space-before="12pt" space-after="6pt">Modern print exemplars</fo:block>
        <!-- witness list -->
         <xsl:apply-templates select="//tei:sourceDesc/tei:listBibl[@xml:id='modern_print_witness']"/>
    </xsl:template>

    <xsl:template name="header">
        <xsl:call-template name="title"/>
        <xsl:call-template name="author"/>
    </xsl:template>

    <xsl:template name="body">
        <xsl:call-template name="introduction"/>
        <xsl:call-template name="transcript"/>
        <xsl:call-template name="mss_witness"/>
        <xsl:call-template name="C17_print_witness"/>
        <xsl:call-template name="modern_print_witness"/>

        <fo:block space-before="24pt" font-family="{$font}" font-size="{$note-size}">&#169; 2018 University of Birmingham,
                        University of Bristol (<xsl:value-of select="$url"/>)
        </fo:block>
    </xsl:template>

    <!-- match root - create FO document -->
    <xsl:template match="/">
        <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
            <fo:layout-master-set>
                <fo:simple-page-master master-name="mpese-text-A4" margin-top="1cm" margin-bottom="1cm"
                                       margin-left="2.5cm" margin-right="2.5cm">
                    <fo:region-body region-name="xsl-region-body" margin-bottom="1cm" margin-top="1cm"/>
                    <fo:region-before region-name="xsl-region-before" extent="1cm"/>
                    <fo:region-after region-name="xsl-region-after" extent="1cm"/>
                </fo:simple-page-master>
            </fo:layout-master-set>
            <fo:page-sequence master-reference="mpese-text-A4" initial-page-number="1">
                <fo:static-content flow-name="xsl-region-before">
                    <fo:block font-family="{$font}" font-size="{$note-size}" text-align="center">Manuscript
                        Pamphleteering in Early Stuart England
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="xsl-region-after">
                    <fo:block font-family="{$font}" font-size="{$note-size}" text-align="center"><fo:page-number/></fo:block>
                </fo:static-content>
                <fo:flow flow-name="xsl-region-body">
                    <xsl:call-template name="header"/>
                    <xsl:call-template name="body"/>
                </fo:flow>
            </fo:page-sequence>
        </fo:root>
    </xsl:template>

    <xsl:template match="tei:TEI">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:text">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:body">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- TEI HEADER-->
    <xsl:template match="tei:teiHeader">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:fileDesc">
        <xsl:apply-templates/>
    </xsl:template>


    <xsl:template match="tei:titleStmt">
        <xsl:call-template name="title"/>
        <xsl:call-template name="author"/>
    </xsl:template>


    <xsl:template match="tei:publicationStmt"/>

    <xsl:template match="tei:sourceDesc"/>

    <xsl:template match="tei:listBibl[@xml:id='mss_witness_generated']">
        <fo:list-block provisional-distance-between-starts="14pt" provisional-label-separation="3pt">
            <xsl:for-each select="tei:bibl">
                <fo:list-item>
                    <fo:list-item-label>
                        <fo:block font-family="{$font}" font-size="{$list-size}" end-indent="label-end()">&#x2022;
                        </fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body start-indent="body-start()">
                        <fo:block font-family="{$font}" font-size="{$list-size}">
                            <xsl:value-of select="."/>
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
            </xsl:for-each>
        </fo:list-block>
    </xsl:template>

    <xsl:template match="tei:listBibl[@xml:id='C17_print_witness']">
        <fo:list-block provisional-distance-between-starts="14pt" provisional-label-separation="3pt">
            <xsl:for-each select="tei:bibl">
                <fo:list-item>
                    <fo:list-item-label>
                        <fo:block font-family="{$font}" font-size="{$list-size}" end-indent="label-end()">&#x2022;
                        </fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body start-indent="body-start()">
                        <fo:block font-family="{$font}" font-size="{$list-size}">
                            <xsl:variable name="place"><xsl:value-of select="./tei:pubPlace"/></xsl:variable>
                            <xsl:variable name="date"><xsl:value-of select="./tei:date"/></xsl:variable>
                            <xsl:variable name="pub_details"><xsl:value-of select="string-join(($place, $date), ', ')"/></xsl:variable>
                            <xsl:choose>
                                <xsl:when test="normalize-space(./tei:author) = ''"/>
                                <xsl:otherwise><xsl:value-of select="normalize-space(./tei:author/string())"/><xsl:text>, </xsl:text></xsl:otherwise>
                            </xsl:choose>
                            <xsl:choose>
                                <xsl:when test="normalize-space(./tei:title) = ''"/>
                                <xsl:otherwise><fo:inline font-style="italic"><xsl:value-of select="normalize-space(./tei:title/string())"/></fo:inline></xsl:otherwise>
                            </xsl:choose>
                            <xsl:choose>
                                <xsl:when test="normalize-space($pub_details) = ''"/>
                                <xsl:otherwise><xsl:text> </xsl:text>(<xsl:value-of select="$pub_details"/>)</xsl:otherwise>
                            </xsl:choose>
                            <xsl:choose>
                                <xsl:when test="normalize-space(./tei:idno) = ''"/>
                                <xsl:otherwise><xsl:text> </xsl:text>[<xsl:value-of select="./tei:idno/@type/string()"/><xsl:text> </xsl:text><xsl:value-of select="./tei:idno/string()"/>]</xsl:otherwise>
                            </xsl:choose>
                            <xsl:choose>
                                <xsl:when test="not(./tei:biblScope)"/>
                                <xsl:otherwise>
                                    <xsl:choose>
                                        <xsl:when test="./tei:biblScope[@unit = 'page']">
                                            <xsl:choose>
                                                <xsl:when test="./tei:biblScope[@unit = 'page']/@from/string() != ./tei:biblScope[@unit = 'page']/@to/string()">
                                                    <xsl:text>, pp. </xsl:text><xsl:value-of select="./tei:biblScope[@unit = 'page']/@from/string()"/>–<xsl:value-of select="./tei:biblScope[@unit = 'page']/@to/string()"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:text>, p. </xsl:text><xsl:value-of select="./tei:biblScope[@unit = 'page']/@from/string()"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:when test="./tei:biblScope[@unit = 'sigs']">
                                            <xsl:choose>
                                                <xsl:when test="./tei:biblScope[@unit = 'sigs']/@from/string() != ./tei:biblScope[@unit = 'sigs']/@to/string()">
                                                    <xsl:text>, sigs. </xsl:text><xsl:value-of select="./tei:biblScope[@unit = 'sigs']/@from/string()"/>–<xsl:value-of select="./tei:biblScope[@unit = 'sigs']/@to/string()"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:text>, sig. </xsl:text><xsl:value-of select="./tei:biblScope[@unit = 'sigs']/@from/string()"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:otherwise/>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
            </xsl:for-each>
        </fo:list-block>
    </xsl:template>




    <xsl:template match="tei:listBibl[@xml:id='modern_print_witness']">
        <fo:list-block provisional-distance-between-starts="14pt" provisional-label-separation="3pt">
            <xsl:for-each select="tei:bibl">
                <!-- start item -->
                <fo:list-item>
                    <!-- item label: bullet point -->
                    <fo:list-item-label>
                        <fo:block font-family="{$font}" font-size="{$list-size}" end-indent="label-end()">&#x2022;
                        </fo:block>
                    </fo:list-item-label>
                    <!-- item body: formatted bibliographic item -->
                    <fo:list-item-body start-indent="body-start()">
                        <!-- author(s) : formatted by function, add a comma at end if we have them -->
                        <xsl:variable name="author">
                            <xsl:choose>
                                <xsl:when test="count(./tei:author) eq 0"/>
                                <xsl:otherwise>
                                    <xsl:value-of select="mpese:authors(./tei:author)"/><xsl:text>, </xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="pubDetails">
                            <xsl:value-of select="mpese:pubDetails(./tei:edition, ./tei:pubPlace, ./tei:date)"/>
                        </xsl:variable>
                        <fo:block font-family="{$font}" font-size="{$list-size}">
                            <!-- author -->
                            <xsl:value-of select="$author"/>
                            <!-- title -->
                            <xsl:choose>
                                <xsl:when test="normalize-space(./tei:title) = ''"/>
                                <xsl:otherwise><fo:inline font-style="italic"><xsl:value-of select="normalize-space(./tei:title)"/></fo:inline></xsl:otherwise>
                            </xsl:choose>
                            <!-- publication details -->
                            <xsl:choose>
                                <xsl:when test="$pubDetails = ''"/>
                                <xsl:otherwise><xsl:text> </xsl:text>(<xsl:value-of select="$pubDetails"/>)</xsl:otherwise>
                            </xsl:choose>
                            <!-- volume -->
                            <xsl:choose>
                                <xsl:when test="./tei:biblScope[@unit = 'volume']">
                                    <xsl:text>, vol. </xsl:text><xsl:value-of select="normalize-space(./tei:biblScope[@unit = 'volume'])"/>
                                </xsl:when>
                            </xsl:choose>
                            <!-- part -->
                            <xsl:choose>
                                <xsl:when test="./tei:biblScope[@unit = 'part']">
                                    <xsl:text>, part. </xsl:text><xsl:value-of select="normalize-space(./tei:biblScope[@unit = 'part'])"/>
                                </xsl:when>
                            </xsl:choose>
                            <!-- page ranges -->
                            <xsl:choose>
                                <!-- Display the page or page range -->
                                <xsl:when test="./tei:biblScope[@unit = 'page']">
                                    <xsl:variable name="page" select="./tei:biblScope[@unit = 'page']"/>
                                    <xsl:value-of select="mpese:pages($page)"/>
                                </xsl:when>
                                <!-- Display the sigs if we don't have pages -->
                                <xsl:when test="./tei:biblScope[@unit = 'sigs'] and not(./tei:biblScope[@unit = 'page'])">
                                    <xsl:variable name="sigs" select="./tei:biblScope[@unit = 'sigs']"/>
                                    <xsl:value-of select="mpese:sigs($sigs)"/>
                                </xsl:when>
                            </xsl:choose>
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
            </xsl:for-each>
        </fo:list-block>
    </xsl:template>


    <xsl:template match="tei:respStmt"></xsl:template>


    <xsl:template match="tei:profileDesc"></xsl:template>

    <!-- paragraphs -->
    <xsl:template match="tei:p|tei:head|tei:closer">
        <xsl:variable name="align">
            <xsl:choose>
                <xsl:when test="@rend = 'align-centre'">center</xsl:when>
                <xsl:otherwise>left</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <fo:block font-family="{$font}" text-align="{$align}" font-size="{$text-size}"
                  space-before="6pt" space-after="6pt">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <!-- expanded text -->
    <xsl:template match="tei:ex">[<xsl:apply-templates/>]</xsl:template>

    <!-- catch words -->
    <xsl:template match="tei:fw">
        <fo:block font-family="{$font}" font-size="{$text-size}" text-align="right"
                  space-before="6pt" space-after="6pt"><xsl:apply-templates/></fo:block></xsl:template>

    <xsl:template match="tei:add">
        <xsl:choose>
            <xsl:when test="@place='LM'">
                [
                <fo:inline font-style="italic">Left margin:</fo:inline>
                <xsl:apply-templates/>]
            </xsl:when>
            <xsl:when test="@place='RM'">
                [
                <fo:inline font-style="italic">Right margin:</fo:inline>
                <xsl:apply-templates/>]
            </xsl:when>
            <xsl:when test="@place='header'">
                <fo:block>
                    <xsl:apply-templates/>
                </fo:block>
            </xsl:when>
            <xsl:when test="@place='above'">
                <fo:inline baseline-shift="super" font-size="smaller">
                    <xsl:apply-templates/>
                </fo:inline>
            </xsl:when>
            <xsl:otherwise>[<xsl:apply-templates/>]
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:pb">
        <fo:block font-family="{$font}" font-size="{$text-size}" font-weight="bold" text-align="center"
                  space-before="6pt" space-after="6pt">
            <xsl:value-of select="@n"/>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:unclear">{<xsl:apply-templates/>}
    </xsl:template>

    <xsl:template match="tei:foreign">
        <fo:inline font-style="italic">
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>

    <!-- TODO: how to show corrections? -->
    <xsl:template match="tei:corr"></xsl:template>

    <!--

Here be dragons ...

Text might be broken up by an <lb break='no'/>, which indicates that the word shouldn't
be broken in rendering. However, the researchers have included a lot of whitespace, including
line breaks for ease of reading the source. The original scribe might also indicate that
a word has been truncated with an equals (=) sign, eg. 'witch= =craft', but we want the word
to appear as 'witchcraft' in the text.

So ... on the text node we check whether or not a sibling is the <lb/> tag with the appropriate
attribute and replace any whitespace and equals with appropriate regex. I expect we will return
to this template often. :-(

-->
    <xsl:template match="text()">
        <xsl:choose>
            <!-- following and preceding siblings are a lb? Strip whitespace and equals -->
            <xsl:when
                    test="./following-sibling::*[1][local-name()='lb' and @break = 'no'] and ./preceding-sibling::*[1][local-name()='lb' and @break = 'no']">
                <xsl:value-of select="replace(., '(=$|(^\s+=?|=?\s+$))', '')"/>
            </xsl:when>
            <!-- following siblings is a lb? Strip whitespace and equals -->
            <xsl:when test="./following-sibling::*[1][local-name()='lb' and @break = 'no']">
                <xsl:value-of select="replace(., '(=$|=?\s+?$)', '')"/>
            </xsl:when>
            <!-- preceding siblings are a lb? Strip whitespace and equals -->
            <xsl:when test="./preceding-sibling::*[1][local-name()='lb' and @break = 'no']">
                <xsl:value-of select="replace(., '(^\s+=?)', '')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>