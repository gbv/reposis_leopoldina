<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="resource:xsl/layout/mir-common-layout.xsl" />
  <xsl:param name="piwikID" select="'0'" />
  <xsl:param name="MIR.TestInstance" />

  <xsl:variable name="checkAdmin" select="document('userobjectrights:isCurrentUserInRole:admin')/boolean='true'"/>
  <xsl:variable name="checkEditor" select="document('userobjectrights:isCurrentUserInRole:editor')/boolean='true'"/>
  <xsl:variable name="checkSubmitter" select="document('userobjectrights:isCurrentUserInRole:submitter')/boolean='true'"/>

  <xsl:template name="mir.navigation">
    <div class="leo-top-nav">
      <div class="container">
        <a href="https://www.leopoldina.org/">
          <span>Zur Homepage der Nationalen Akademie der Wissenschaften Leopoldina</span>
        </a>
      </div>
    </div>
    <div id="header_box" class="clearfix container">
      <div id="options_nav_box" class="mir-prop-nav">
        <xsl:if test="contains($MIR.TestInstance, 'true')">
          <div id="watermark_testenvironment">Testumgebung</div>
        </xsl:if>
        <nav>
          <ul class="navbar-nav ml-auto flex-row">
            <xsl:call-template name="mir.loginMenu" />
            <xsl:call-template name="mir.languageMenu" />
          </ul>
        </nav>
      </div>
      <div id="project_logo_box">
        <a href="https://www.leopoldina.org/" class="leo-logo__link">
          <img src="{$WebApplicationBaseURL}images/logo-leopoldina-blue-1024.jpg" class="leo-logo__figure" alt="" />
        </a>
        <a
          href="{concat($WebApplicationBaseURL,substring($loaded_navigation_xml/@hrefStartingPage,2),$HttpSession)}"
          class="project-logo">
          Digitale Bibliothek</a>
      </div>
      <div class="searchBox">
        <xsl:variable name="core">
          <xsl:call-template name="get-layout-search-solr-core" />
        </xsl:variable>
        <form
          action="{$WebApplicationBaseURL}servlets/solr{$core}"
          class="searchfield_box form-inline my-2 my-lg-0"
          role="search">
          <input
            name="condQuery"
            placeholder="{document('i18n:mir.navsearch.placeholder')/i18n/text()}"
            class="form-control search-query"
            id="searchInput"
            type="text"
            aria-label="Search" />
          <xsl:choose>
            <xsl:when test="$checkAdmin or $checkEditor">
              <input name="owner" type="hidden" value="createdby:*" />
            </xsl:when>
            <xsl:when test="not($CurrentUser='guest')">
              <input name="owner" type="hidden" value="createdby:{$CurrentUser}" />
            </xsl:when>
          </xsl:choose>
          <button type="submit" class="btn btn-primary my-2 my-sm-0">
            <i class="fas fa-search"></i>
          </button>
        </form>
      </div>
    </div>
    <!-- Collect the nav links, forms, and other content for toggling -->
    <div class="mir-main-nav bg-primary">
      <div class="container">
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
          <button
            class="navbar-toggler"
            type="button"
            data-toggle="collapse"
            data-target="#mir-main-nav__entries"
            aria-controls="mir-main-nav__entries"
            aria-expanded="false"
            aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
          </button>
          <div id="mir-main-nav__entries" class="collapse navbar-collapse mir-main-nav__entries">
            <ul class="navbar-nav mr-auto mt-2 mt-lg-0">
              <xsl:call-template name="leo.generate_single_menu_entry">
                <xsl:with-param name="menuID" select="'brand'" />
              </xsl:call-template>
              <xsl:call-template name="leo.generate_single_menu_entry">
                <xsl:with-param name="menuID" select="'current'" />
              </xsl:call-template>
              <xsl:apply-templates select="$loaded_navigation_xml/menu[@id='search']" />
              <xsl:apply-templates select="$loaded_navigation_xml/menu[@id='publish']" />
              <xsl:call-template name="mir.basketMenu" />
            </ul>
          </div>
        </nav>
      </div>
    </div>
  </xsl:template>

  <xsl:template name="mir.jumbotwo">
    <!-- ignore -->
  </xsl:template>

  <xsl:template name="mir.footer">
    <div class="container">
      <div class="row">
        <div class="col">
          <ul class="internal_links nav navbar-nav">
            <xsl:apply-templates select="$loaded_navigation_xml/menu[@id='below']/*" mode="footerMenu" />
          </ul>
        </div>
      </div>
    </div>
  </xsl:template>

  <xsl:template name="leo.generate_single_menu_entry">
    <xsl:param name="menuID" />
    <xsl:variable name="menu-item" select="$loaded_navigation_xml/menu[@id=$menuID]/item" />
    <li class="nav-item">
      <xsl:variable name="active-class">
        <xsl:choose>
          <xsl:when test="$menu-item/@href = $browserAddress">
            <xsl:text>active</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>not-active</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="full-url">
        <xsl:call-template name="resolve-full-url">
          <xsl:with-param name="link" select="$menu-item/@href" />
        </xsl:call-template>
      </xsl:variable>
      <a id="{$menuID}" href="{$full-url}" class="nav-link {$active-class}">
        <xsl:apply-templates select="$menu-item" mode="linkText" />
      </a>
    </li>
  </xsl:template>

  <xsl:template name="resolve-full-url">
    <xsl:param name="link" />
    <xsl:param name="base-url" select="$WebApplicationBaseURL" />
    <xsl:choose>
      <xsl:when test="starts-with($link,'http:')
                      or starts-with($link,'https:')
                      or starts-with($link,'mailto:')
                      or starts-with($link,'ftp:')">
        <xsl:value-of select="$link" />
      </xsl:when>
      <xsl:when test="starts-with($link,'/')">
        <xsl:choose>
          <xsl:when test="substring($base-url, string-length($base-url), 1) = '/'">
            <xsl:value-of
              select="concat(substring($base-url, 1, string-length($base-url) - 1), $link)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($base-url, $link)" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="substring($base-url, string-length($base-url), 1) = '/'">
            <xsl:value-of select="concat($base-url, $link)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($base-url, '/', $link)" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="mir.powered_by">
    <xsl:variable name="mcr-version" select="document('version:full')/version/text()" />
    <div id="powered_by">
      <a href="https://www.mycore.de">
        <img
          src="{$WebApplicationBaseURL}mir-layout/images/mycore_logo_small_invert.png"
          title="{$mcr-version}"
          alt="powered by MyCoRe" />
      </a>
    </div>

    <!-- Matomo -->
    <xsl:if test="$piwikID &gt; 0">
      <script>
        var _paq = _paq || [];
        _paq.push(['setDoNotTrack', true]);
        _paq.push(['trackPageView']);
        _paq.push(['enableLinkTracking']);
        (function() {
        var u="https://matomo.gbv.de/";
        var objectID = '<xsl:value-of select="//site/@ID" />';
        if(objectID != "") {
        _paq.push(["setCustomVariable",1, "object", objectID, "page"]);
        }
        _paq.push(['setTrackerUrl', u+'piwik.php']);
        _paq.push(['setSiteId', '<xsl:value-of select="$piwikID" />']);
        _paq.push(['setDownloadExtensions', '7z|aac|arc|arj|asf|asx|avi|bin|bz|bz2|csv|deb|dmg|doc|exe|flv|gif|gz|gzip|hqx|jar|jpg|jpeg|js|mp2|mp3|mp4|mpg|mpeg|mov|movie|msi|msp|odb|odf|odg|odp|ods|odt|ogg|ogv|pdf|phps|png|ppt|qt|qtm|ra|ram|rar|rpm|sea|sit|tar|tbz|tbz2|tgz|torrent|txt|wav|wma|wmv|wpd|z|zip']);
        var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
        g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
        })();
      </script>
      <noscript>
        <p>
          <img src="https://matomo.gbv.de/piwik.php?idsite={$piwikID}" style="border:0;" alt="" />
        </p>
      </noscript>
    </xsl:if>
    <!-- End Piwik Code -->
  </xsl:template>

  <xsl:template name="get-layout-search-solr-core">
    <xsl:choose>
      <xsl:when test="$checkAdmin or $checkEditor or $checkSubmitter">
        <xsl:text>/find</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/findPublic</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
