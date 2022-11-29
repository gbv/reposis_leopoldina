package de.vzg.leopoldina;

import org.mycore.common.MCRSessionMgr;
import org.mycore.common.MCRUserInformation;
import org.mycore.common.config.MCRConfiguration2;
import org.mycore.datamodel.metadata.MCRBase;
import org.mycore.datamodel.metadata.MCRMetaEnrichedLinkID;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.services.i18n.MCRTranslation;
import org.mycore.user2.MCRUser;
import org.mycore.user2.MCRUserManager;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class LeopoldinaEditorUtil {

    private static final Set<String> fileContain = MCRConfiguration2.getString("Leopoldina.Workflow.FileContainsWarning")
        .map(MCRConfiguration2::splitValue)
        .orElseGet(Stream::empty)
        .collect(Collectors.toUnmodifiableSet());

    public static String getFileWarning(String id) {
        MCRObjectID objectID = MCRObjectID.getInstance(id);
        MCRObject object = MCRMetadataManager.retrieveMCRObject(objectID);
        return object.getStructure().getDerivates().stream()
            .map(MCRMetaEnrichedLinkID::getMainDoc)
            .filter(file -> fileContain.stream().anyMatch(fileContain::contains))
            .map(file -> MCRTranslation.translate("mir.workflow.file.warnings", file))
            .collect(Collectors.joining(", "));
    }

    public static String getClassificationValue() {
        Optional<String> mayInstitute = getClassificationValueOptional();

        if (mayInstitute.isPresent()) {
            return mayInstitute.get();
        } else {
            return "none";
        }
    }

    public static boolean hasClassificationValue() {
        return getClassificationValueOptional().isPresent();
    }

    public static boolean hasNoClassificationValue() {
        return getClassificationValueOptional().isEmpty();
    }

    private static Optional<String> getClassificationValueOptional() {
        MCRUserInformation userInformation = MCRSessionMgr.getCurrentSession().getUserInformation();
        String userID = userInformation.getUserID();

        MCRUser user = MCRUserManager.getUser(userID);
        Optional<String> mayInstitute = user.getExternalRoleIDs().stream()
            .filter(role -> role.startsWith("mir_institutes:"))
            .map(role -> role.substring("mir_institutes:".length()))
            .findFirst();
        return mayInstitute;
    }
}
