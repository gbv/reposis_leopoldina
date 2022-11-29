package de.vzg.leopoldina;

import org.mycore.access.MCRAccessManager;
import org.mycore.common.MCRSessionMgr;
import org.mycore.common.config.MCRConfiguration2;
import org.mycore.datamodel.classifications2.MCRCategoryDAO;
import org.mycore.datamodel.classifications2.MCRCategoryDAOFactory;
import org.mycore.datamodel.classifications2.MCRLabel;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.datamodel.metadata.MCRObjectService;
import org.mycore.mods.MCRMODSWrapper;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

public class LeopoldinaOrderUtil {


    public static final MCRCategoryDAO CATEGORY_DAO = MCRCategoryDAOFactory.getInstance();

    private static final Set<String> ALREADY_SEND_MAILS = new HashSet<>();

    public static boolean changeOrderableAllowed(MCRObjectID objectID) {
        String creator = getObjectCreator(objectID);
        return equalsWithCurrentUser(creator) || hasSetOrderPriv();
    }

    public static boolean changeOrderableAllowed(String objectID) {
        return changeOrderableAllowed(MCRObjectID.getInstance(objectID));
    }

    public static String getTargetMail(String objectID) {
        MCRObject mcrObject = MCRMetadataManager.retrieveMCRObject(MCRObjectID.getInstance(objectID));
        MCRMODSWrapper modsWrapper = new MCRMODSWrapper(mcrObject);

        String to = modsWrapper.getMcrCategoryIDs().stream()
                .filter(id -> id.getRootID().equals("mir_institutes"))
                .filter(CATEGORY_DAO::exist)
                .map(id -> CATEGORY_DAO.getCategory(id, 0))
                .map(category -> category.getLabel("x-mail"))
                .filter(Optional::isPresent)
                .map(Optional::get)
                .map(MCRLabel::getText)
                .collect(Collectors.joining(","));

        if (to.length() == 0) {
            to = MCRConfiguration2.getStringOrThrow("Leopoldina.Order.Mail");
        }
        return to;
    }

    public static void markMailSend(String mailid) {
        ALREADY_SEND_MAILS.add(mailid);
    }

    public static boolean wasMailSend(String mailid) {
        return ALREADY_SEND_MAILS.contains(mailid);
    }

    public static boolean isFulltextPresent(String idObj) {
        MCRObject object = MCRMetadataManager.retrieveMCRObject(MCRObjectID.getInstance(idObj));
        return object.getStructure().getDerivates()
                .stream()
                .anyMatch(der -> der.getMainDoc() != null && der.getMainDoc().endsWith(".pdf"));
    }

    private static String encode(String mailToBuilder) {
        return URLEncoder.encode(mailToBuilder.toString(), StandardCharsets.UTF_8).replace("+", "%20");
    }

    private static String getObjectCreator(MCRObjectID objectID) {
        MCRObject object = MCRMetadataManager.retrieveMCRObject(objectID);
        return object.getService().getFlags(MCRObjectService.FLAG_TYPE_CREATEDBY).stream().findFirst().orElse(null);
    }

    private static boolean hasSetOrderPriv() {
        return MCRAccessManager.checkPermission(LeopoldinaOrderServlet.USE_SET_ORDER_PRIV);
    }

    private static boolean equalsWithCurrentUser(String creator) {
        return creator != null && MCRSessionMgr.getCurrentSession().getUserInformation().getUserID().equals(creator);
    }
}
