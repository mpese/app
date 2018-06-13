<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei"
    version="2.0">

    <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

    <xsl:strip-space elements="*" />

    <xsl:template match="/"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:TEI"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:text"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:body"><xsl:apply-templates/></xsl:template>

    <!-- stuff to ignore -->
    <xsl:template match="tei:teiHeader"/>

    <xsl:template match="tei:choice"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:p|tei:head|tei:opener|tei:closer"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:list"><xsl:text>&#xd;</xsl:text><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:item"><xsl:apply-templates/><xsl:text>&#xa;</xsl:text></xsl:template>

    <xsl:template match="tei:lb">
        <xsl:choose>
            <xsl:when test="@break eq 'no'"><xsl:text></xsl:text></xsl:when>
            <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:lg"><xsl:text>&#xd;</xsl:text><xsl:apply-templates/><xsl:text>&#xd;</xsl:text></xsl:template>

    <xsl:template match="tei:l"><xsl:apply-templates/><xsl:text>&#xa;</xsl:text></xsl:template>

    <xsl:template match="tei:expan">
        <xsl:text> </xsl:text>
        <xsl:choose>
            <xsl:when test="parent::tei:choice"/>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:ex"><xsl:apply-templates/></xsl:template>

    <!-- don't show catchwords -->
    <xsl:template match="tei:fw"/>

    <xsl:template name="abbr" match="tei:abbr"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:hi"><xsl:apply-templates/></xsl:template>

    <!-- page beginning: don't show -->
    <xsl:template match="tei:pb"/>

    <!-- add: ignore marginalia -->
    <xsl:template match="tei:add">
        <xsl:choose>
            <xsl:when test="@place='LM'"/>
            <xsl:when test="@place='RM'"/>
            <xsl:when test="@place='header'"><xsl:apply-templates/></xsl:when>
            <xsl:when test="@place='above'"><xsl:apply-templates/></xsl:when>
            <xsl:otherwise ><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:seg"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:signed"><xsl:apply-templates/></xsl:template>

    <!-- deleted: don't show -->
    <xsl:template match="tei:del"/>

    <xsl:template match="tei:milestone"><xsl:apply-templates/></xsl:template>

    <!-- supplied: just show -->
    <xsl:template match="tei:supplied"><xsl:apply-templates/></xsl:template>

    <!-- unclear: just show -->
    <xsl:template match="tei:unclear"><xsl:apply-templates/></xsl:template>

    <!-- gap: leave small amount of white space -->
    <xsl:template match="tei:gap"><xsl:text>   </xsl:text><xsl:apply-templates/></xsl:template>

    <!-- foreign words -->
    <xsl:template match="tei:foreign"><xsl:apply-templates/></xsl:template>

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
            <xsl:when test="./following-sibling::*[1][local-name()='lb' and @break = 'no'] and ./preceding-sibling::*[1][local-name()='lb' and @break = 'no']">
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
                <xsl:value-of select="replace(., '[ ]{2,}', ' ')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--<xsl:template match="*">-->
        <!--<xsl:message terminate="no">-->
            <!--WARNING: Unmatched element: <xsl:value-of select="name()"/>-->
        <!--</xsl:message>-->
        <!---->
        <!--<xsl:apply-templates/>-->
    <!--</xsl:template>-->

</xsl:stylesheet>