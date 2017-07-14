<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    exclude-result-prefixes="xs w"
    version="2.0">

    <xsl:template match="w:p">
        <p><xsl:apply-templates select="w:r"/></p>
    </xsl:template>

    <xsl:template match="w:rPr">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="w:r">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="w:r">
        <xsl:value-of select="w:t"/>
    </xsl:template>

</xsl:stylesheet>