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
import org.mycore.common.events.MCRStartupHandler;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.solr.MCRSolrClientFactory;
import org.mycore.util.concurrent.MCRFixedUserCallable;

import javax.servlet.ServletContext;
import java.io.IOException;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Consumer;
import java.util.stream.Collectors;

public class MCRPublishCronJob extends TimerTask implements MCRStartupHandler.AutoExecutable {

    private static final Logger LOGGER = LogManager.getLogger();

    private static final int TIMER_TASK_PERIOD = getTimerPause();// * 60 * 3;

    private static final int RELEASE_THREAD_COUNT = 3;

    private static final ExecutorService EXECUTOR_SERVICE = Executors.newFixedThreadPool(RELEASE_THREAD_COUNT);
    private static final String MODS_PUBLISH_DATE_SOLR = "mods.publish.date";

    private static int getTimerPause() {
        return MCRConfiguration2.getOrThrow("MCR.Publish.Job.Schedule.WaitInMinutes", Integer::parseInt) * 1000
            * 60;
    }

    @Override
    public String getName() {
        return "Object Publisher";
    }

    @Override
    public int getPriority() {
        return 0;
    }

    @Override
    public void startUp(ServletContext servletContext) {
        final Timer t = new Timer();
        t.scheduleAtFixedRate(this, 0, TIMER_TASK_PERIOD);
    }

    private void searchDocumentsToRelease(Consumer<MCRObjectID> objectReleaser) {
        if (MCRConfiguration2.getString("MCR.Solr.ServerURL").isPresent()) {
            final SolrClient solrClient = MCRSolrClientFactory.getMainSolrClient();
            final ModifiableSolrParams params = new ModifiableSolrParams();
            final LocalDate today = LocalDate.now(ZoneOffset.UTC);
            final String todayString = today.format(DateTimeFormatter.ISO_DATE);

            params.set("start", 0);
            params.set("rows", Integer.MAX_VALUE - 1);
            params.set("fl", "id");
            params.set("q", MODS_PUBLISH_DATE_SOLR + ":[* TO " + todayString + "]");
            params.set("fq", "state:publishable");

            try {
                final QueryResponse response = solrClient.query(params);
                Set<MCRFixedUserCallable<Boolean>> releaseCallables = response.getResults().stream()
                    .map(result -> (String) result.get("id"))
                    .map(MCRObjectID::getInstance)
                    .map(id -> new MCRFixedUserCallable<>(() -> {
                        objectReleaser.accept(id);
                        return true;
                    }, MCRSystemUserInformation.getSuperUserInstance())).collect(Collectors.toSet());

                EXECUTOR_SERVICE.invokeAll(releaseCallables);
            } catch (SolrServerException | IOException | InterruptedException e) {
                LOGGER.error("Error while searching embargo documents!", e);
            }
        }
    }

    @Override
    public void run() {
        LOGGER.info("Running " + getName() + "..");
        searchDocumentsToRelease(this::releaseDocument);
    }

    private void releaseDocument(MCRObjectID mcrObjectID) {
        if (MCRMetadataManager.exists(mcrObjectID)) {
            final MCRObject mcrObject = MCRMetadataManager.retrieveMCRObject(mcrObjectID);
            mcrObject.getService().setState("published");
            try {
                MCRMetadataManager.update(mcrObject);
            } catch (MCRAccessException e) {
                throw new MCRException("Error while publishing " + mcrObjectID.toString() + "!", e);
            }
        }
    }

}
