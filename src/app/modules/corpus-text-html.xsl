<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei"
    version="2.0">

    <xsl:output method="xml" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="tei:choice tei:expan tei:body tei:p tei:del tei:gap" />

    <xsl:template match="/"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:TEI">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:text">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:body">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- stuff to ignore -->
    <xsl:template match="tei:teiHeader"></xsl:template>

    <xsl:template match="tei:choice"><xsl:call-template name="abbr"/></xsl:template>

    <xsl:template match="tei:p">
        <xsl:choose>
            <xsl:when test="@rend != ''">
                <p class="{@rend}"><xsl:apply-templates/></p>
            </xsl:when>
            <xsl:otherwise>
                <p><xsl:apply-templates/></p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:head">
        <xsl:choose>
            <xsl:when test="@rend='align-centre'"><p class="text-center"><xsl:apply-templates/></p></xsl:when>
            <xsl:otherwise><p><xsl:apply-templates/></p></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:opener">
        <xsl:choose>
            <xsl:when test="@rend != ''">
                <p class="{@rend}"><xsl:apply-templates/></p>
            </xsl:when>
            <xsl:otherwise>
                <p><xsl:apply-templates/></p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:closer">
        <xsl:choose>
            <xsl:when test="@rend != ''">
                <p class="{@rend}"><xsl:apply-templates/></p>
            </xsl:when>
            <xsl:otherwise>
                <p><xsl:apply-templates/></p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:list">
        <xsl:choose>
            <xsl:when test="contains(@rend, 'numbered')">
                <ol><xsl:apply-templates/></ol>
            </xsl:when>
            <xsl:otherwise>
                <ul><xsl:apply-templates/></ul>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:item"><li><xsl:apply-templates/></li></xsl:template>

    <xsl:template match="tei:lb">
        <xsl:choose>
            <xsl:when test="@break eq 'no'"><xsl:text></xsl:text></xsl:when>
            <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:lg"><p><xsl:apply-templates/></p></xsl:template>

    <xsl:template match="tei:l"><xsl:apply-templates/><br/></xsl:template>

    <xsl:template match="tei:expan">
        <xsl:text> </xsl:text>
        <xsl:choose>
            <xsl:when test="parent::tei:choice"></xsl:when>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:ex">[<xsl:apply-templates/>]</xsl:template>

    <xsl:template name="abbr" match="tei:abbr"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:hi">
        <xsl:choose>
            <xsl:when test="@rend != ''">
                <span class="{@rend}"><xsl:apply-templates/></span>
            </xsl:when>
            <xsl:otherwise>
                <span><xsl:apply-templates/></span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:pb">
        <xsl:choose>
            <xsl:when test="@facs">
                <p class='mpese-pb'>
                    <xsl:attribute name="data-facs"><xsl:value-of select='@facs'/></xsl:attribute>
                    <xsl:value-of select="@n"/><xsl:text> </xsl:text><span class="mpese-photo glyphicon glyphicon-camera small" aria-hidden="true"></span></p>
            </xsl:when>
            <xsl:otherwise>
                <p class='mpese-pb'><xsl:value-of select="@n"/></p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:add">
        <xsl:choose>
            <xsl:when test="@place='LM'"><span class="mpese-add-lm"><em class="mpese-lm-note">Left margin: </em> <xsl:apply-templates/></span></xsl:when>
            <xsl:when test="@place='RM'"><span class="mpese-add-rm"><em class="mpese-rm-note">Right margin: </em> <xsl:apply-templates/></span></xsl:when>
            <xsl:when test="@place='header'"><span class="tei-add-header"><xsl:apply-templates/></span></xsl:when>
            <xsl:when test="@place='above'"><span class="superscript"><xsl:apply-templates/></span></xsl:when>
            <xsl:otherwise ><span class="mpese-add">[<xsl:apply-templates/>]</span></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:seg">
        <xsl:choose>
            <xsl:when test="@rend != ''">
                <span class="{@rend} tei-seg"><xsl:apply-templates/></span>
            </xsl:when>
            <xsl:otherwise>
                <span class="tei-seg"><xsl:apply-templates/></span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:signed">
        <xsl:choose>
            <xsl:when test="@rend != ''">
                <span class="{@rend} tei-signed"><xsl:apply-templates/></span>
            </xsl:when>
            <xsl:otherwise>
                <span class="tei-signed"><xsl:apply-templates/></span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:del">
        <xsl:choose>
            <xsl:when test="@rend != ''">
                <del class="{@rend} tei-del"><xsl:apply-templates/></del>
            </xsl:when>
            <xsl:otherwise>
                <del class="tei-del"><xsl:apply-templates/></del>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:milestone">
        <xsl:choose>
            <xsl:when test="@type eq 'separator' and @unit eq 'nonstructural' and @rend='horizontal-line'">
                <hr class="tei-milestone"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

     <xsl:template match="tei:unclear"><span class="tei-unclear">{<xsl:apply-templates/>}</span></xsl:template>

    <xsl:template match="tei:gap"><span class="mpese-gap"><xsl:apply-templates/></span></xsl:template>

    <xsl:template match="tei:foreign"><em><xsl:apply-templates/></em></xsl:template>

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
                <xsl:value-of select="."/>
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