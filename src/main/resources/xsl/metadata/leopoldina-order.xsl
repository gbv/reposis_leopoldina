<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:i18n="xalan://org.mycore.services.i18n.MCRTranslation"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:mods="http://www.loc.gov/mods/v3"
                xmlns:mcrxsl="xalan://org.mycore.common.xml.MCRXMLFunctions"
                xmlns:order="xalan://de.vzg.leopoldina.LeopoldinaOrderUtil"
                xmlns:orderDAO="xalan://de.vzg.leopoldina.LeopoldinaCanOrderDAO"
                xmlns:xalan="http://xml.apache.org/xalan"
                xmlns:exslt="http://exslt.org/common"
                version="1.0"
                exclude-result-prefixes="i18n mods xlink mcrxsl xalan exslt"
>

    <xsl:import href="xslImport:modsmeta:metadata/leopoldina-order.xsl"/>
    <xsl:variable name="objectID" select="/mycoreobject/@ID"/>

    <xsl:template match="/">
        <xsl:if test="order:isFulltextPresent($objectID)">
            <xsl:variable name="canChangeOrderable" select="order:changeOrderableAllowed($objectID)"/>
            <xsl:variable name="canOrder" select="orderDAO:getCanOrder($objectID)"/>
            <xsl:if test="$canChangeOrderable or $canOrder">
                <div id="leopoldina-order">
                    <xsl:if test="$canChangeOrderable">
                        <form method="GET" action="{$WebApplicationBaseURL}servlets/LeopoldinaOrderServlet">
                            <input type="hidden" name="objID" value="{$objectID}"/>
                            <input type="hidden" name="action" value="change"/>
                            <xsl:choose>
                                <xsl:when test="$canOrder">
                                    <input type="hidden" name="canOrder" value="false"/>
                                    <input type="submit" class="btn btn-secondary w-100" style="white-space: normal;"
                                           value="{i18n:translate('leopoldina.make.not.orderable')}"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <input type="hidden" name="canOrder" value="true"/>
                                    <input type="submit" class="btn btn-secondary w-100" style="white-space: normal;"
                                           value="{i18n:translate('leopoldina.make.orderable')}"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </form>
                        <hr/>
                    </xsl:if>
                    <xsl:if test="$canOrder">
                        <script src="{$WebApplicationBaseURL}js/leopoldina-order.js" type="text/javascript"></script>

                        <button type="button" class="btn btn-primary w-100" data-toggle="modal"
                                data-target="#leopoldina-order-modal">
                            <xsl:value-of select="i18n:translate('leopoldina.order')"/>
                        </button>

                        <!-- Modal -->
                        <div class="modal fade" id="leopoldina-order-modal" tabindex="-1" role="dialog"
                             aria-labelledby="exampleModalLabel" aria-hidden="true">
                            <div class="modal-dialog modal-lg" role="document">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <h5 class="modal-title" id="exampleModalLabel">
                                            <xsl:value-of
                                                    select="i18n:translate('mir.metaData.panel.heading.leopoldina-order')"/>
                                        </h5>
                                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                            <span aria-hidden="true">&#215;</span>
                                        </button>
                                    </div>
                                    <div class="modal-body">
                                        <div class="row form-row mt-1">
                                            <div class="col-4">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.email')"/>
                                            </div>
                                            <div class="col-8">
                                                <input type="email" id="order-email" class="form-control"
                                                       placeholder="{i18n:translate('leopoldina.order.modal.form.email.placeholder')}"
                                                       value=""/>
                                                <input type="hidden" id="order-object-id" value="{$objectID}"/>
                                            </div>
                                        </div>
                                        <div class="row form-row mt-1">
                                            <div class="col-4">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.name')"/>
                                            </div>
                                            <div class="col-8">
                                                <input type="text" id="order-name" class="form-control"
                                                       minlength="5"
                                                       placeholder="{i18n:translate('leopoldina.order.modal.form.name.placeholder')}"
                                                       value=""/>
                                            </div>
                                        </div>
                                        <div class="row form-row mt-1">
                                            <div class="col-4">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.address')"/>
                                            </div>
                                            <div class="col-8">
                                                <textarea type="text" id="order-address" class="form-control" rows="4" minlength="0" maxlength="500"
                                                          placeholder="{i18n:translate('leopoldina.order.modal.form.address.placeholder')}"/>
                                            </div>
                                        </div>
                                        <div class="row form-row mt-1">
                                            <div class="col-4">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.amount')"/>
                                            </div>
                                            <div class="col-8">
                                                <input type="number" id="order-amount" class="form-control" value="1" min="1" max="99" />
                                            </div>
                                        </div>
                                        <div class="row form-row mt-1">
                                            <div class="col-4">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.comment')"/>
                                            </div>
                                            <div class="col-8">
                                                <textarea id="order-comment" class="form-control" rows="3"
                                                          placeholder="{i18n:translate('leopoldina.order.modal.form.comment.placeholder')}"> </textarea>
                                            </div>
                                        </div>
                                        <div class="row form-row mt-1">
                                            <div class="col-4">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.captcha')"/>
                                            </div>
                                            <div class="col-8">
                                                <div class="row">
                                                    <div class="col-6 justify-content-center align-self-center">
                                                        <img id="captcha-image"
                                                             src="{$WebApplicationBaseURL}servlets/LeopoldinaOrderServlet?action=captcha"
                                                             alt="captcha" class="img-fluid"/>
                                                    </div>
                                                    <div class="col-6 justify-content-center align-self-center">
                                                        <input type="text" id="captcha-input" class="form-control"
                                                               placeholder="{i18n:translate('leopoldina.order.modal.form.captcha.placeholder')}"
                                                               value=""/>
                                                    </div>
                                                </div>
                                                <div class="row">
                                                    <div class="col-6">
                                                        <a href="#" id="captcha-refresh">
                                                            <xsl:value-of
                                                                    select="i18n:translate('leopoldina.order.modal.form.captcha.refresh')"/>
                                                        </a>
                                                    </div>
                                                    <div class="col-6">
                                                        <a href="#play" id="captcha-play">
                                                            <xsl:value-of
                                                                    select="i18n:translate('leopoldina.order.modal.form.captcha.play')"/>
                                                        </a>
                                                        <a href="#stop" id="captcha-stop" class="d-none">
                                                            <xsl:value-of
                                                                    select="i18n:translate('leopoldina.order.modal.form.captcha.stop')"/>
                                                        </a>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="row mt-1">
                                            <div class="col-12">
                                                <div class="alert alert-danger d-none" role="alert" id="order-error">
                                                    <xsl:value-of
                                                            select="i18n:translate('leopoldina.order.modal.form.error')"/>
                                                </div>
                                                <div class="alert alert-success d-none" role="alert" id="order-success">
                                                    <xsl:value-of
                                                            select="i18n:translate('leopoldina.order.modal.form.success')"/>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="modal-footer">
                                            <button type="button" class="btn btn-secondary" data-dismiss="modal"
                                                    id="order-cancel">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.cancel')"/>
                                            </button>
                                            <button type="button" class="btn btn-primary" id="order-submit">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.submit')"/>
                                            </button>
                                            <button type="button" class="btn btn-primary d-none" data-dismiss="modal"
                                                    id="order-close">
                                                <xsl:value-of
                                                        select="i18n:translate('leopoldina.order.modal.form.close')"/>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </xsl:if>
                </div>
            </xsl:if>
        </xsl:if>

        <xsl:apply-imports/>
    </xsl:template>

</xsl:stylesheet>