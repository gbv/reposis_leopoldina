<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:mods="http://www.loc.gov/mods/v3"
  exclude-result-prefixes="mods">

  <xsl:import href="xslImport:solr-document:leopoldina-solr.xsl" />

  <xsl:template match="mycoreobject[contains(@ID,'_mods_')]">
    <xsl:apply-imports />
    <!-- fields from mycore-mods -->
    <xsl:for-each select="service/servflags[@class='MCRMetaLangText']/servflag[@type='publish_date']">
      <field name="flag.publish.date">
        <xsl:value-of select="." />
      </field>
    </xsl:for-each>

    <field name="mods.findable">
      <xsl:choose>
        <xsl:when test="metadata/def.modsContainer/modsContainer/mods:mods/mods:classification[@displayLabel='findable']">
          <xsl:value-of select="substring-after(metadata/def.modsContainer/modsContainer/mods:mods/mods:classification[@displayLabel='findable']/@valueURI,'#')" />
        </xsl:when>
        <xsl:otherwise>true</xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>

</xsl:stylesheet>
