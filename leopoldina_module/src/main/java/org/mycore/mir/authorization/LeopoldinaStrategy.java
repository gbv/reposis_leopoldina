package org.mycore.mir.authorization;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.mycore.access.MCRAccessManager;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.mods.MCRMODSEmbargoUtils;

public class LeopoldinaStrategy extends MIRStrategy {

    private static final MIRKeyStrategyHelper KEY_STRATEGY_HELPER = new MIRKeyStrategyHelper();

    private static final Logger LOGGER = LogManager.getLogger();

    @Override
    public boolean checkPermission(String id, String permission) {
        if(MCRObjectID.isValid(id)){
            final MCRObjectID objectId = MCRObjectID.getInstance(id);
            String embargo = MCRMODSEmbargoUtils.getEmbargo(objectId);
            if (MCRAccessManager.PERMISSION_READ.equals(permission)
                    && embargo != null
                    && (!MCRMODSEmbargoUtils.isCurrentUserCreator(objectId))) {
                LOGGER.debug("Object {} has embargo {} check if user can write it!", objectId, embargo);
                return super.checkPermission(id, MCRAccessManager.PERMISSION_WRITE);
            }
        }

        return super.checkPermission(id, permission);
    }
}
