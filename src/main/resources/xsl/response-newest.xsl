<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:include href="MyCoReLayout.xsl" />
  <xsl:include href="response-utils.xsl" />
  <xsl:include href="xslInclude:solrResponse" />

  <xsl:param name="WebApplicationBaseURL" />

  <xsl:variable name="PageTitle">
    <xsl:value-of select="document('i18n:lp.newestObjects')/i18n/text()" />
  </xsl:variable>

  <xsl:template match="/response/result|lst[@name='grouped']/lst[@name='returnId']" priority="20">
    <div class="row result_head">
      <div class="col-12 result_headline">
        <h1>
          <xsl:value-of select="$PageTitle" />
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
    </div>
    <xsl:if test="string-length($MCR.ORCID.OAuth.ClientSecret) &gt; 0">
      <script src="{$WebApplicationBaseURL}js/mir/mycore2orcid.js" />
    </xsl:if>
    <script>
      // remove unwanted xsl style part from hit link
      document.addEventListener("DOMContentLoaded", function () {
        document.querySelectorAll(".hit_title a").forEach(function (el) {
          el.href = el.href.replace("XSL.Style=newest&amp;", "");
        });
      });
    </script>
  </xsl:template>

</xsl:stylesheet>
