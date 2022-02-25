package de.vzg.leopoldina;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.solr.client.solrj.SolrClient;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.params.ModifiableSolrParams;
import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRException;
import org.mycore.common.MCRSystemUserInformation;
import org.mycore.common.config.MCRConfiguration2;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.mcr.cronjob.MCRCronjob;
import org.mycore.solr.MCRSolrClientFactory;
import org.mycore.util.concurrent.MCRFixedUserCallable;

import java.io.IOException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAccessor;
import java.util.ArrayList;

public class LeopoldinaPublishCronjob extends MCRCronjob {

    private static final Logger LOGGER = LogManager.getLogger();

    private static final String PUBLISH_DATA_FIELD = "flag.publish.date";
    public static final String PUBLISHED_STATE = "published";

    private void releaseDocument(MCRObjectID mcrObjectID) {
        if (MCRMetadataManager.exists(mcrObjectID)) {
            final MCRObject mcrObject = MCRMetadataManager.retrieveMCRObject(mcrObjectID);
            // just another check because we can not trust solr
            if (isStatePublishable(mcrObject) && isPublishDatePastOrNotPresent(mcrObject)) {
                LOGGER.info("Publish document {}", mcrObjectID);
                mcrObject.getService().setState(PUBLISHED_STATE);
                try {
                    MCRMetadataManager.update(mcrObject);
                } catch (MCRAccessException e) {
                    throw new MCRException("Error while publishing " + mcrObjectID.toString() + "!", e);
                }
            }
        }
    }

    private static boolean isPublishDatePastOrNotPresent(MCRObject mcrObject) {
        final ArrayList<String> publishDate = mcrObject.getService().getFlags("publish_date");
        if (publishDate.size() == 0) {
            return true;
        }
        return publishDate.stream().anyMatch(LeopoldinaPublishCronjob::isPastDate);
    }

    private static boolean isPastDate(String s) {
        final ZonedDateTime now = ZonedDateTime.now();
        final TemporalAccessor parse = DateTimeFormatter.ISO_DATE.parse(s);
        final ZonedDateTime zonedDateTime = LocalDate
            .from(parse)
            .atTime(0, 0, 0, 0)
            .atZone(ZoneId.systemDefault());
        return now.isAfter(zonedDateTime);
    }

    private boolean isStatePublishable(MCRObject mcrObject) {
        return mcrObject.getService().getState() != null
            && !mcrObject.getService().getState().getID().equals(PUBLISHED_STATE);
    }

    @Override
    public void runJob() {
        try {
            new MCRFixedUserCallable<Boolean>(() -> {
                if (MCRConfiguration2.getString("MCR.Solr.ServerURL").isPresent()) {
                    final SolrClient solrClient = MCRSolrClientFactory.getMainSolrClient();
                    final ModifiableSolrParams params = new ModifiableSolrParams();
                    final LocalDate today = LocalDate.now(ZoneOffset.UTC);
                    final String todayString = today.format(DateTimeFormatter.ISO_DATE);

                    params.set("start", 0);
                    params.set("rows", Integer.MAX_VALUE - 1);
                    params.set("fl", "id");
                    params.set("q", PUBLISH_DATA_FIELD + ":[* TO " + todayString + "] OR (*:* AND !" + PUBLISH_DATA_FIELD + ":*)");
                    params.set("fq", "state:publishable");

                    try {
                        final QueryResponse response = solrClient.query(params);
                        response.getResults().stream()
                            .map(result -> (String) result.get("id"))
                            .map(MCRObjectID::getInstance)
                            .forEach(this::releaseDocument);

                    } catch (SolrServerException | IOException e) {
                        LOGGER.error("Error while searching embargo documents!", e);
                    }
                }
                return true;
            }, MCRSystemUserInformation.getSuperUserInstance()).call();
        } catch (Exception e) {
            LOGGER.error("Errow while calling cron job", e);
        }
    }

    @Override
    public String getDescription() {
        return "Cronjob for releasing publishable Objects were release data <now";
    }
}
