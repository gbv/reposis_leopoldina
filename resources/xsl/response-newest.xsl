<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:encoder="xalan://java.net.URLEncoder"
  xmlns:i18n="xalan://org.mycore.services.i18n.MCRTranslation" xmlns:str="http://exslt.org/strings" xmlns:exslt="http://exslt.org/common" xmlns:mcr="xalan://org.mycore.common.xml.MCRXMLFunctions"
  xmlns:acl="xalan://org.mycore.access.MCRAccessManager" xmlns:mcrxsl="xalan://org.mycore.common.xml.MCRXMLFunctions" xmlns:basket="xalan://org.mycore.frontend.basket.MCRBasketManager"
  xmlns:decoder="xalan://java.net.URLDecoder" exclude-result-prefixes="i18n mods str exslt mcr acl mcrxsl basket encoder decoder"
  >
  <xsl:include href="MyCoReLayout.xsl" />
  <xsl:include href="response-utils.xsl" />
  <xsl:include href="xslInclude:solrResponse" />
  
  <xsl:param name="WebApplicationBaseURL" />

  <xsl:variable name="PageTitle">
    <xsl:value-of select="i18n:translate('lp.newestObjects')" />
  </xsl:variable>

  <xsl:template match="/response/result|lst[@name='grouped']/lst[@name='returnId']" priority="20">
    
    <div class="row result_head">
      <div class="col-12 result_headline">
        <h1>
          <xsl:value-of select="i18n:translate('lp.newestObjects')" />
        </h1>
      </div>
    </div>
    
    <!-- Filter, Pagination & Trefferliste -->
    <div class="row result_body">
      
      <div class="col-12 col-sm-8 result_list">
        <xsl:comment>
          RESULT LIST START
        </xsl:comment>
        <div id="hit_list">
          <xsl:apply-templates select="doc|arr[@name='groups']/lst/str[@name='groupValue']" mode="resultList" />
        </div>
        <xsl:comment>
          RESULT LIST END
        </xsl:comment>
        <div class="result_list_end" />
      </div>
      
      <div class="col-12 col-sm-4 result_filter">
        <xsl:if test="/response/lst[@name='facet_counts']/lst[@name='facet_fields']/lst[@name='worldReadableComplete']/int">
          <div class="card oa">
            <div class="card-header" data-toggle="collapse-next">
              <h3 class="card-title">
                <xsl:value-of select="i18n:translate('mir.response.openAccess.facet.title')" />
              </h3>
            </div>
            <div class="card-body collapse show">
              <ul class="filter">
                <xsl:apply-templates select="/response/lst[@name='facet_counts']/lst[@name='facet_fields']">
                  <xsl:with-param name="facet_name" select="'worldReadableComplete'" />
                  <xsl:with-param name="i18nPrefix" select="'mir.response.openAccess.facet.'" />
                </xsl:apply-templates>
              </ul>
            </div>
          </div>
        </xsl:if>
        <xsl:if test="/response/lst[@name='facet_counts']/lst[@name='facet_fields']/lst[@name='mods.genre']/int">
          <div class="card genre">
            <div class="card-header" data-toggle="collapse-next">
              <h3 class="card-title">
                <xsl:value-of select="i18n:translate('editor.search.mir.genre')" />
              </h3>
            </div>
            <div class="card-body collapse show">
              <ul class="filter">
                <xsl:apply-templates select="/response/lst[@name='facet_counts']/lst[@name='facet_fields']">
                  <xsl:with-param name="facet_name" select="'mods.genre'" />
                  <xsl:with-param name="classId" select="'mir_genres'" />
                </xsl:apply-templates>
              </ul>
            </div>
          </div>
        </xsl:if>
        <xsl:if test="$MIR.testEnvironment='true'"> <!-- filters in development, show only in test environments -->
          <xsl:call-template name="print.classiFilter">
            <xsl:with-param name="classId" select="'mir_institutes'" />
            <xsl:with-param name="i18nKey" select="'editor.search.mir.institute'" />
          </xsl:call-template>
          <xsl:call-template name="print.classiFilter">
            <xsl:with-param name="classId" select="'SDNB'" />
            <xsl:with-param name="i18nKey" select="'editor.search.mir.sdnb'" />
          </xsl:call-template>
          <xsl:call-template name="print.dateFilter" />
        </xsl:if>
      </div>
      
    </div>
    <xsl:if test="string-length($MCR.ORCID.OAuth.ClientSecret) &gt; 0">
      <script src="{$WebApplicationBaseURL}js/mir/mycore2orcid.js" />
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>