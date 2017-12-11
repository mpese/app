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

    <xsl:template match="tei:p"><p><xsl:apply-templates/></p></xsl:template>

    <xsl:template match="tei:lb"> </xsl:template>

    <xsl:template match="tei:expan">
        <xsl:choose>
            <xsl:when test="parent::tei:choice"></xsl:when>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:ex"><em><xsl:apply-templates/></em></xsl:template>

    <xsl:template name="abbr" match="tei:abbr"><xsl:apply-templates/></xsl:template>

    <xsl:template match="tei:hi">
        <xsl:choose>
            <xsl:when test="@rend='bold'"><strong><xsl:apply-templates/></strong></xsl:when>
            <xsl:when test="@rend='superscript'"><sup><xsl:apply-templates/></sup></xsl:when>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
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
            <xsl:otherwise ><span class="mpese-add">[<xsl:apply-templates/>]</span></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:del"><del><xsl:apply-templates/></del></xsl:template>

     <xsl:template match="tei:unclear"><span class="unclear"><xsl:apply-templates/></span></xsl:template>

    <xsl:template match="tei:gap"><span class="mpese-gap"><xsl:apply-templates/></span></xsl:template>

    <!--<xsl:template match="*">-->
        <!--<xsl:message terminate="no">-->
            <!--WARNING: Unmatched element: <xsl:value-of select="name()"/>-->
        <!--</xsl:message>-->
        <!---->
        <!--<xsl:apply-templates/>-->
    <!--</xsl:template>-->

</xsl:stylesheet>