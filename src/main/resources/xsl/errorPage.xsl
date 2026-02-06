<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:variable name="Type" select="'document'" />
  <xsl:variable name="PageTitle" select="document(concat('i18n:titles.pageTitle.error: ', /mcr_error/@HttpError))/i18n/text()" />

  <xsl:template match="/mcr_error">
    <h1>Es ist ein Fehler aufgetreten</h1>
    <div class="row">
      <div class="col-md-8" lang="de">
        <xsl:choose>
          <xsl:when test="/mcr_error/@HttpError = '500'">
            <h2>Interner Serverfehler</h2>
            <p>
              Es ist leider ein Serverfehler aufgetreten. Wir arbeiten an dessen Beseitigung! Gern können Sie uns eine
              Mail an <span class="madress">dms-list [at] lists.gbv.de</span> schicken und kurz schildern wie es zu
              diesem Fehler kam.
            </p>
            <p>Vielen Dank!</p>
          </xsl:when>
          <xsl:when test="/mcr_error/@HttpError = '404'">
            <h2>
              <xsl:value-of select="." />
            </h2>
            <p>
              Die von Ihnen angeforderte Seite konnte leider nicht gefunden werden. Eventuell haben Sie ein altes
              Lesezeichen oder einen veralteten Link benutzt. Bitte versuchen Sie mithilfe der
              <a href="/index.html"> Suche</a> die gewünschte Seite zu finden oder schreiben Sie eine Mail an
              <span class="madress">bibliothek [at] leopoldina.org</span> und schildern kurz wie es zu diesem Fehler kam.
            </p>
            <p>Vielen Dank!</p>
          </xsl:when>
          <xsl:when test="/mcr_error/@HttpError = '403'">
            <h2>Zugriff verweigert</h2>
            <p>
              Sie haben keine Berechtigung diese Seite zu sehen. Melden Sie sich bitte am System an. Sollten Sie trotz
              Anmeldung nicht die nötigen Rechte haben, um diese Seite zu sehen, wenden Sie sich ggf. an Ihren
              Administrator oder schreiben Sie eine Mail an <span class="madress">bibliothek [at] leopoldina.org</span>.
            </p>
            <p>Vielen Dank!</p>
          </xsl:when>
          <xsl:when test="/mcr_error/@HttpError = '400' and @errorServlet and string-length(text()) &gt; 1">
            <h2>Ungültige Anfrage</h2>
            <p>
              <xsl:call-template name="lf2br">
                <xsl:with-param name="string" select="text()" />
              </xsl:call-template>
            </p>
            <p>
              Wenn Sie der Meinung sind, dass dies ein Fehler ist, schreiben Sie bitte eine Mail an
              <span class="madress">dms-list [at] lists.gbv.de</span> und schildern kurz wie es dazu kam.
            </p>
            <a href="javascript:history.back()" class="btn btn-secondary float-right">
              <xsl:value-of select="document('i18n:leopoldina.error.back')/i18n/text()" />
            </a>
          </xsl:when>
          <xsl:otherwise>
            <h2>
              <xsl:value-of select="." />
            </h2>
            <p>
              Es ist leider ein Fehler aufgetreten. Sollte dies wiederholt der Fall sein, schreiben Sie bitte eine Mail
              an <span class="madress">dms-list [at] lists.gbv.de</span> und schildern kurz wie es dazu kam.
            </p>
            <p>Vielen Dank!</p>
          </xsl:otherwise>
        </xsl:choose>
      </div>
      <xsl:if test="exception">
        <div class="hidden">
          <div class="panel panel-warning">
            <div class="panel-heading">
              <xsl:value-of select="concat(document('i18n:error.stackTrace')/i18n/text(),' :')" />
            </div>
            <div class="panel-body">
              <xsl:for-each select="exception/trace">
                <pre style="font-size:0.8em;">
                  <xsl:value-of select="." />
                </pre>
              </xsl:for-each>
            </div>
          </div>
        </div>
      </xsl:if>
    </div>
  </xsl:template>

  <xsl:include href="MyCoReLayout.xsl" />

</xsl:stylesheet>
