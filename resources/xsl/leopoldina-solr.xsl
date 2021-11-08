<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
        version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:mods="http://www.loc.gov/mods/v3"
        xmlns:mcrxsl="xalan://org.mycore.common.xml.MCRXMLFunctions"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        exclude-result-prefixes="mods mcrxsl xlink"
>
    <xsl:import href="xslImport:solr-document:leopoldina-solr.xsl" />

    <xsl:template match="mycoreobject[contains(@ID,'_mods_')]">
        <xsl:apply-imports />
        <!-- fields from mycore-mods -->
        <xsl:for-each select="metadata/def.modsContainer/modsContainer/mods:mods/mods:originInfo[not(@eventType) or @eventType='publication']/mods:dateIssued[not(@point='end')]">
            <field name="mods.publish.date">
                <xsl:value-of select="." />
            </field>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
