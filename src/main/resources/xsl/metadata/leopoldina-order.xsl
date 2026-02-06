<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:order="xalan://de.vzg.leopoldina.LeopoldinaOrderUtil"
  xmlns:orderDAO="xalan://de.vzg.leopoldina.LeopoldinaCanOrderDAO"
  exclude-result-prefixes="order orderDAO">

  <xsl:import href="xslImport:modsmeta:metadata/leopoldina-order.xsl" />

  <xsl:variable name="object-id" select="/mycoreobject/@ID" />
  <xsl:variable name="is-fulltext-present" select="order:isFulltextPresent($object-id)" />
  <xsl:variable name="can-change-orderable" select="order:changeOrderableAllowed($object-id)" />
  <xsl:variable name="can-order" select="orderDAO:getCanOrder($object-id)" />

  <xsl:template match="/">
    <xsl:if test="$is-fulltext-present">
      <xsl:if test="$can-change-orderable or $can-order">
        <div id="leopoldina-order">
          <xsl:if test="$can-change-orderable">
            <xsl:call-template name="display-order-form" />
            <hr />
          </xsl:if>
          <xsl:if test="$can-order">
            <button type="button" class="btn btn-primary w-100" data-toggle="modal" data-target="#leopoldina-order-modal">
              <xsl:value-of select="document('i18n:leopoldina.order')/i18n/text()" />
            </button>
            <xsl:call-template name="display-order-modal" />
          </xsl:if>
          <script src="{$WebApplicationBaseURL}js/leopoldina-order.js" type="text/javascript"></script>
        </div>
      </xsl:if>
    </xsl:if>
    <xsl:apply-imports />
  </xsl:template>

  <xsl:template name="display-order-form">
    <form method="GET" action="{$WebApplicationBaseURL}servlets/LeopoldinaOrderServlet">
      <input type="hidden" name="objID" value="{$object-id}" />
      <input type="hidden" name="action" value="change" />
      <xsl:choose>
        <xsl:when test="$can-order">
          <input type="hidden" name="canOrder" value="false" />
          <input
            type="submit"
            class="btn btn-secondary w-100"
            style="white-space: normal;"
            value="{document('i18n:leopoldina.make.not.orderable')/i18n/text()}"  />
        </xsl:when>
        <xsl:otherwise>
          <input type="hidden" name="canOrder" value="true" />
          <input
            type="submit"
            class="btn btn-secondary w-100"
            style="white-space: normal;"
            value="{document('i18n:leopoldina.make.orderable')/i18n/text()}" />
        </xsl:otherwise>
      </xsl:choose>
    </form>
  </xsl:template>

  <xsl:template name="display-order-modal">
    <div class="modal fade" id="leopoldina-order-modal" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
      <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="exampleModalLabel">
              <xsl:value-of select="document('i18n:mir.metaData.panel.heading.leopoldina-order')/i18n/text()" />
            </h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&#215;</span>
            </button>
          </div>
          <div class="modal-body">
            <div class="row form-row mt-1">
              <div class="col-4">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.email')/i18n/text()" />
              </div>
              <div class="col-8">
                <input
                  type="email"
                  id="order-email"
                  class="form-control"
                  placeholder="{document('i18n:leopoldina.order.modal.form.email.placeholder')/i18n/text()}"
                  value="" />
                <input type="hidden" id="order-object-id" value="{$object-id}" />
              </div>
            </div>
            <div class="row form-row mt-1">
              <div class="col-4">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.name')/i18n/text()" />
              </div>
              <div class="col-8">

                <input
                  type="text"
                  id="order-name"
                  class="form-control"
                  minlength="5"
                  placeholder="{document('i18n:leopoldina.order.modal.form.name.placeholder')/i18n/text()}"
                  value="" />
              </div>
            </div>
            <div class="row form-row mt-1">
              <div class="col-4">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.address')/i18n/text()" />
              </div>
              <div class="col-8">
                <textarea
                  type="text"
                  id="order-address"
                  class="form-control"
                  rows="4"
                  minlength="0"
                  maxlength="500"
                  placeholder="{document('i18n:leopoldina.order.modal.form.address.placeholder')/i18n/text()}" />
              </div>
            </div>
            <div class="row form-row mt-1">
              <div class="col-4">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.amount')/i18n/text()" />
              </div>
              <div class="col-8">
                <input type="number" id="order-amount" class="form-control" value="1" min="1" max="99" />
              </div>
            </div>
            <div class="row form-row mt-1">
              <div class="col-4">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.comment')/i18n/text()" />
              </div>
              <div class="col-8">
                <textarea
                  id="order-comment"
                  class="form-control"
                  rows="3"
                  placeholder="{document('i18n:leopoldina.order.modal.form.comment.placeholder')/i18n/text()}"></textarea>
              </div>
            </div>
            <div class="row form-row mt-1">
              <div class="col-4">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.captcha')/i18n/text()" />
              </div>
              <div class="col-8">
                <div class="row">
                  <div class="col-6 justify-content-center align-self-center">
                    <img
                      id="captcha-image"
                      src="{$WebApplicationBaseURL}servlets/LeopoldinaOrderServlet?action=captcha"
                      alt="captcha"
                      class="img-fluid" />
                  </div>
                  <div class="col-6 justify-content-center align-self-center">
                    <input
                      type="text"
                      id="captcha-input"
                      class="form-control"
                      placeholder="{document('i18n:leopoldina.order.modal.form.captcha.placeholder')/i18n/text()}"
                      value="" />
                  </div>
                </div>
                <div class="row">
                  <div class="col-6">
                    <a href="#" id="captcha-refresh">
                      <xsl:value-of select="document('i18n:leopoldina.order.modal.form.captcha.refresh')/i18n/text()" />
                    </a>
                  </div>
                  <div class="col-6">
                    <a href="#play" id="captcha-play">
                      <xsl:value-of select="document('i18n:leopoldina.order.modal.form.captcha.play')/i18n/text()" />
                    </a>
                    <a href="#stop" id="captcha-stop" class="d-none">
                      <xsl:value-of select="document('i18n:leopoldina.order.modal.form.captcha.stop')/i18n/text()" />
                    </a>
                  </div>
                </div>
              </div>
            </div>
            <div class="row mt-1">
              <div class="col-12">
                <div class="alert alert-danger d-none" role="alert" id="order-error">
                  <xsl:value-of select="document('i18n:leopoldina.order.modal.form.error')/i18n/text()" />
                </div>
                <div class="alert alert-success d-none" role="alert" id="order-success">
                  <xsl:value-of select="document('i18n:leopoldina.order.modal.form.success')/i18n/text()" />
                </div>
              </div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-dismiss="modal" id="order-cancel">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.cancel')/i18n/text()" />
              </button>
              <button type="button" class="btn btn-primary" id="order-submit">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.submit')/i18n/text()" />
              </button>
              <button type="button" class="btn btn-primary d-none" data-dismiss="modal" id="order-close">
                <xsl:value-of select="document('i18n:leopoldina.order.modal.form.close')/i18n/text()" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </xsl:template>

</xsl:stylesheet>
