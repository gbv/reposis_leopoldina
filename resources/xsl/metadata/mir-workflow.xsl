<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:i18n="xalan://org.mycore.services.i18n.MCRTranslation"
                xmlns:exslt="http://exslt.org/common"
                xmlns:mods="http://www.loc.gov/mods/v3"
                version="1.0" exclude-result-prefixes="i18n exslt mods">

  <xsl:import href="xslImport:modsmeta:metadata/mir-workflow.xsl"/>
  <xsl:import href="xslImport:mirworkflow:metadata/mir-workflow.xsl"/>

  <xsl:param name="layout" select="'$'"/>
  <xsl:param name="MIR.Workflow.Box" select="'false'"/>
  <xsl:param name="MIR.Workflow.ReviewDerivateRequired" select="'true'"/>
  <xsl:param name="CurrentUser"/>

  <xsl:param name="MIR.Workflow.Debug" select="'false'"/>
  <xsl:key use="@id" name="rights" match="/mycoreobject/rights/right"/>
  <xsl:variable name="id" select="/mycoreobject/@ID"/>

  <xsl:include href="workflow-util.xsl"/>


  <xsl:template match="/">
    <xsl:if test="normalize-space($MIR.Workflow.Box)='true'">
      <div id="mir-workflow" class="col-sm-12">
        <xsl:variable name="statusClassification" select="document('classification:metadata:-1:children:state')"/>
        <xsl:variable name="currentStatus"
                      select="/mycoreobject/service/servstates/servstate[@classid='state']/@categid"/>
        <xsl:variable name="creator" select="/mycoreobject/service/servflags/servflag[@type='createdby']/text()"/>
        <!-- Write -->
        <xsl:choose>
          <xsl:when test="$currentStatus='new'">
            <xsl:choose>
              <xsl:when test="$CurrentUser=$creator">
                <xsl:apply-templates mode="creatorNew"/>
              </xsl:when>
              <xsl:when test="key('rights', mycoreobject/@ID)/@write">
                <xsl:apply-templates mode="editorNew"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          
          <xsl:when test="$currentStatus='submitted'">
            <xsl:choose>
              <xsl:when test="$CurrentUser=$creator">
                <xsl:apply-templates mode="creatorSubmitted"/>
              </xsl:when>
              <xsl:when test="key('rights', mycoreobject/@ID)/@write">
                <xsl:apply-templates mode="editorSubmitted"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          
          <xsl:when test="$currentStatus='review'">
            <xsl:choose>
              <xsl:when test="key('rights', mycoreobject/@ID)/@write">
                <xsl:apply-templates mode="editorReview"/>
              </xsl:when>
              <xsl:when test="$CurrentUser=$creator">
                <xsl:apply-templates mode="creatorReview"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </div>
    </xsl:if>
    <xsl:apply-imports/>
  </xsl:template>


  <xsl:template match="mycoreobject" mode="creatorNew">
    <xsl:if test="normalize-space($MIR.Workflow.Debug)='true'">
      <xsl:message>
        creatorNew
        Nutzer Ersteller
        Dokument new
      </xsl:message>
    </xsl:if>

    <xsl:if test="key('rights', @ID)/@write">
      <xsl:variable name="currentStatus"
                    select="service/servstates/servstate[@classid='state']/@categid"/>
      <xsl:variable name="editURL">
        <xsl:call-template name="getEditURL">
          <xsl:with-param name="id" select="$id" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="message">
        <p>
          <xsl:if test="metadata/def.modsContainer/modsContainer/mods:mods/mods:note[@type='editor2author']">
            <xsl:value-of select="'Ihre Einreichung wurde von der Leopoldina-Bibliothek mit folgender Anmerkung zurückgewiesen:'" /><br />
            <span class="pl-4">
              <xsl:value-of select="metadata/def.modsContainer/modsContainer/mods:mods/mods:note[@type='editor2author']"/>
            </span>
          </xsl:if>
        </p>
        <p>
          <xsl:value-of select="i18n:translate('mir.workflow.creator.new')"/>
          <ul>
            <li>
              <a href="{$editURL}">
                <xsl:value-of select="i18n:translate('mir.workflow.editObject')"/>
              </a>
            </li>
            <xsl:apply-templates select="." mode="creatorNewAdd" />
            <xsl:choose>
              <xsl:when test="normalize-space($MIR.Workflow.ReviewDerivateRequired) = 'true' and not(structure/derobjects/derobject/maindoc)">
                <li>
                  <a href="#">
                    <xsl:attribute name="onclick">document.querySelector('[data-upload-object]').scrollIntoView({behavior: 'smooth', block: 'center', inline: 'nearest'}); return false;</xsl:attribute>
                    <xsl:value-of select="i18n:translate('mir.workflow.creator.new.require.derivate')"/>
                  </a>
                </li>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="listStatusChangeOptions">
                  <xsl:with-param name="class" select="''"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </ul>
        </p>
      </xsl:variable>
      <xsl:call-template name="buildLayout">
        <xsl:with-param name="content" select="exslt:node-set($message)"/>
        <xsl:with-param name="heading" select="''"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="mycoreobject" mode="editorNew" priority="10">
    <xsl:if test="normalize-space($MIR.Workflow.Debug)='true'">
      <xsl:message>
        editorNew
        Nutzer editor
        Dokument new
      </xsl:message>
    </xsl:if>
    <xsl:variable name="message">
      <p>
        <xsl:value-of select="i18n:translate('mir.workflow.editor.new')"/>
      </p>
    </xsl:variable>
    <xsl:call-template name="buildLayout">
      <xsl:with-param name="content" select="exslt:node-set($message)"/>
      <xsl:with-param name="heading" select="''"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="mycoreobject" mode="creatorSubmitted" priority="10">
    <xsl:if test="normalize-space($MIR.Workflow.Debug)='true'">
      <xsl:message>
        editorSubmitted
        Nutzer editor
        Dokument submitted
      </xsl:message>
    </xsl:if>
    <xsl:variable name="message">
      <p>
        <xsl:value-of select="i18n:translate('mir.workflow.creator.submitted')"/>
      </p>
    </xsl:variable>
    <xsl:call-template name="buildLayout">
      <xsl:with-param name="content" select="exslt:node-set($message)"/>
      <xsl:with-param name="heading" select="''"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="mycoreobject" mode="editorSubmitted" priority="10">
    <xsl:if test="normalize-space($MIR.Workflow.Debug)='true'">
      <xsl:message>
        editorSubmitted
        Nutzer editor
        Dokument submitted
      </xsl:message>
    </xsl:if>
    <xsl:variable name="message">
      <p>
        <xsl:value-of select="i18n:translate('mir.workflow.editor.submitted')"/>
        <ul>
          <xsl:apply-templates select="." mode="editorSubmittedAdd" />
          <xsl:call-template name="listStatusChangeOptions">
            <xsl:with-param name="class" select="''"/>
          </xsl:call-template>
        </ul>
      </p>
    </xsl:variable>
    <xsl:call-template name="buildLayout">
      <xsl:with-param name="content" select="exslt:node-set($message)"/>
      <xsl:with-param name="heading" select="''"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="mycoreobject" mode="creatorReview" priority="10">
    <xsl:if test="normalize-space($MIR.Workflow.Debug)='true'">
      <xsl:message>
        creatorReview
        Nutzer creator
        Dokument review
      </xsl:message>
    </xsl:if>
    <xsl:variable name="message">
      <p>
        <xsl:value-of select="i18n:translate('mir.workflow.creator.review')"/>
      </p>
    </xsl:variable>
    <xsl:call-template name="buildLayout">
      <xsl:with-param name="content" select="exslt:node-set($message)"/>
      <xsl:with-param name="heading" select="''"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="mycoreobject" mode="editorReview" priority="10">
    <xsl:if test="normalize-space($MIR.Workflow.Debug)='true'">
      <xsl:message>
        editorReview
        Nutzer editor
        Dokument review
      </xsl:message>
    </xsl:if>
    <xsl:variable name="editURL">
      <xsl:call-template name="getEditURL">
        <xsl:with-param name="id" select="$id"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="message">
      <p>
        <xsl:value-of select="i18n:translate('mir.workflow.editor.review')"/>
        <ul>
          <li>
            <a href="{$editURL}">
              <xsl:value-of select="i18n:translate('object.editObject')"/>
            </a>
          </li>
          <xsl:apply-templates select="." mode="editorReviewAdd" />
          <xsl:call-template name="listStatusChangeOptions">
            <xsl:with-param name="class" select="''"/>
          </xsl:call-template>
        </ul>
      </p>
      <p>
        <xsl:if test="//metadata/def.modsContainer/modsContainer/mods:mods/mods:note[@type='author2editor']">
          <xsl:value-of select="'Der / Die Einreichende macht dazu folgende Anmerkung:'" /><br />
          <span class="pl-4">
            <xsl:value-of select="//metadata/def.modsContainer/modsContainer/mods:mods/mods:note[@type='author2editor']"/>
          </span>
        </xsl:if>
      </p>
    </xsl:variable>
    <xsl:call-template name="buildLayout">
      <xsl:with-param name="content" select="exslt:node-set($message)"/>
      <xsl:with-param name="heading" select="''"/>
    </xsl:call-template>
  </xsl:template>


  <xsl:template match="mycoreobject" mode="creatorNewAdd" priority="10">
  </xsl:template>

  <xsl:template match="mycoreobject" mode="editorSubmittedAdd" priority="10">
  </xsl:template>

  <xsl:template match="mycoreobject" mode="editorReviewAdd" priority="10">
  </xsl:template>

  <xsl:template name="getEditURL">
    <xsl:param name="id"/>
    <xsl:variable name="adminEditURL">
      <xsl:value-of xmlns:actionmapping="xalan://org.mycore.wfc.actionmapping.MCRURLRetriever"
                    select="actionmapping:getURLforID('update-admin',$id,true())"/>
    </xsl:variable>
    <xsl:variable name="normalEditURL">
      <xsl:call-template name="mods.getObjectEditURL">
        <xsl:with-param name="id" select="$id"/>
        <xsl:with-param name="layout" select="$layout"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($adminEditURL)&gt;0">
        <xsl:value-of select="$adminEditURL"/><xsl:text>&amp;id=</xsl:text><xsl:value-of select="$id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$normalEditURL"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="buildLayout" priority="10">
    <xsl:param name="heading"/>
    <xsl:param name="content"/>
    <div class="workflow-box">
      <xsl:if test="string-length(normalize-space($heading))&gt;0">
        <h1>
          <xsl:value-of select="$heading"/>
        </h1>
      </xsl:if>
      <xsl:copy-of select="$content"/>
    </div>
  </xsl:template>
</xsl:stylesheet>