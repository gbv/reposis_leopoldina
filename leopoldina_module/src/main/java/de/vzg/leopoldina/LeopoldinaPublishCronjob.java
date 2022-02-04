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
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

public class LeopoldinaPublishCronjob extends MCRCronjob {

    private static final Logger LOGGER = LogManager.getLogger();

    private static final int RELEASE_THREAD_COUNT = 3;

    private static final ExecutorService EXECUTOR_SERVICE = Executors.newFixedThreadPool(RELEASE_THREAD_COUNT);
    private static final String PUBLISH_DATA_FIELD = "flag.publish.date";

    private void releaseDocument(MCRObjectID mcrObjectID) {
        if (MCRMetadataManager.exists(mcrObjectID)) {
            LOGGER.info("Publish document {}", mcrObjectID);
            final MCRObject mcrObject = MCRMetadataManager.retrieveMCRObject(mcrObjectID);
            mcrObject.getService().setState("published");
            try {
                MCRMetadataManager.update(mcrObject);
            } catch (MCRAccessException e) {
                throw new MCRException("Error while publishing " + mcrObjectID.toString() + "!", e);
            }
        }
    }



    @Override
    public void runJob() {
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
                Set<MCRFixedUserCallable<Boolean>> releaseCallables = response.getResults().stream()
                        .map(result -> (String) result.get("id"))
                        .map(MCRObjectID::getInstance)
                        .map(id -> new MCRFixedUserCallable<>(() -> {
                            this.releaseDocument(id);
                            return true;
                        }, MCRSystemUserInformation.getSuperUserInstance())).collect(Collectors.toSet());

                EXECUTOR_SERVICE.invokeAll(releaseCallables);
            } catch (SolrServerException | IOException | InterruptedException e) {
                LOGGER.error("Error while searching embargo documents!", e);
            }
        }
    }

    @Override
    public String getDescription() {
        return "Cronjob for releasing publishable Objects were release data <now";
    }
}
