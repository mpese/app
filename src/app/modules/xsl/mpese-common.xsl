<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:mpese="http://mpese.ac.uk"
                exclude-result-prefixes="xs"
                version="2.0">

    <!-- Authors: format a list of authors with appropriate commas etc. -->
    <xsl:function name="mpese:authors">
        <xsl:param name="authors"/>
        <xsl:choose>
            <!-- no authors, no content -->
            <xsl:when test="count($authors) eq 0"/>
            <!-- more than one author - handle formatting -->
            <xsl:when test="count($authors) &gt; 1">
                <xsl:for-each select="$authors">
                    <xsl:choose>
                        <xsl:when test="position() eq 1">
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:when>
                        <xsl:when test="position() eq last()">
                            <xsl:text> and </xsl:text><xsl:value-of select="."/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>, </xsl:text><xsl:value-of select="normalize-space(.)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <!-- one author -->
            <xsl:otherwise><xsl:value-of select="normalize-space($authors)"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- publication details -->
    <xsl:function name="mpese:pubDetails">
        <xsl:param name="pubEdition"/>
        <xsl:param name="pubPlace"/>
        <xsl:param name="pubDate"/>
        <xsl:choose>
            <xsl:when test="$pubPlace eq '' and $pubDate eq ''"/>
            <xsl:otherwise>
                <xsl:value-of select="string-join(($pubEdition, $pubPlace, $pubDate), ', ')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Display the page or page range -->
    <xsl:function name="mpese:page-range">
        <xsl:param name="page"/>
        <xsl:choose>
            <xsl:when test="$page/@from/string() eq $page/@to/string()">
                <xsl:value-of select="$page/@from/string()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$page/@from/string()"/>–<xsl:value-of select="$page/@to/string()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Display the page prefix (p. or pp.) and page range -->
    <xsl:function name="mpese:pages">
        <xsl:param name="page"/>
        <xsl:choose>
            <!-- multiple page ranges found -->
            <xsl:when test="count($page) &gt; 1">
                <xsl:text>, pp. </xsl:text>
                <xsl:for-each select="$page">
                    <xsl:choose>
                        <xsl:when test="position() eq last()">
                            <xsl:text> and </xsl:text><xsl:value-of select="mpese:page-range(.)"/>
                        </xsl:when>
                        <xsl:when test="position() eq 1">
                            <xsl:value-of select="mpese:page-range(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>, </xsl:text><xsl:value-of select="mpese:page-range(.)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <!-- single page range -->
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$page/@from/string() != $page/@to/string()">
                        <xsl:text>, pp. </xsl:text><xsl:value-of select="mpese:page-range($page)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>, p. </xsl:text><xsl:value-of select="mpese:page-range($page)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Display the sigs. prefix (sig. or sigs.) and range -->
    <xsl:function name="mpese:sigs">
        <xsl:param name="page"/>
        <xsl:choose>
            <!-- multiple page ranges found -->
            <xsl:when test="count($page) &gt; 1">
                <xsl:text>, sigs. </xsl:text>
                <xsl:for-each select="$page">
                    <xsl:choose>
                        <xsl:when test="position() eq last()">
                            <xsl:text> and </xsl:text><xsl:value-of select="mpese:page-range(.)"/>
                        </xsl:when>
                        <xsl:when test="position() eq 1">
                            <xsl:value-of select="mpese:page-range(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>, </xsl:text><xsl:value-of select="mpese:page-range(.)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <!-- single page range -->
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$page/@from/string() != $page/@to/string()">
                        <xsl:text>, sigs. </xsl:text><xsl:value-of select="mpese:page-range($page)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>, sig. </xsl:text><xsl:value-of select="mpese:page-range($page)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>