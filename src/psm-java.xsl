<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" />

<xsl:template match="/">
    <xsl:apply-templates select="//interface"/>
</xsl:template>

<xsl:template match="interface">
interface <xsl:value-of select="@name"/> {
<xsl:apply-templates select="operation" mode="java-interface"/>}
</xsl:template>

<xsl:template match="operation" mode="java-interface">
    <xsl:value-of select="@visibility"
    />&#160;<xsl:value-of select="@typename"
    />&#160;<xsl:value-of select="@name"
    />(<xsl:for-each select="parameter"
    >
        <xsl:value-of select="@typename"/>&#160;<xsl:value-of select="@name"/>
        <xsl:if test="following-sibling::parameter">, </xsl:if>
    </xsl:for-each>);
</xsl:template>
</xsl:stylesheet>