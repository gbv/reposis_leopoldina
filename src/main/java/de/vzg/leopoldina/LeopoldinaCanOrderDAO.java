package de.vzg.leopoldina;

import java.util.ArrayList;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRException;
import org.mycore.common.MCRSystemUserInformation;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.util.concurrent.MCRFixedUserCallable;

public class LeopoldinaCanOrderDAO {

    public static final String FLAG_CAN_ORDER = "canOrder";

    private final static ThreadPoolExecutor executor
        = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<Runnable>());

    public static void setCanOrder(MCRObjectID idObj, boolean canOrder) throws MCRAccessException {
        String id = idObj.toString();
        if (!MCRMetadataManager.exists(idObj)) {
            throw new IllegalArgumentException("The object " + id + " does not exist!");
        }

        MCRObject object = MCRMetadataManager.retrieveMCRObject(idObj);
        ArrayList<String> existingFlags = object.getService().getFlags(FLAG_CAN_ORDER);
        if (existingFlags.size() > 1) {
            throw new IllegalStateException(
                "The object " + id + " has more than one flag of type " + FLAG_CAN_ORDER + "!");
        }
        for (String flag : existingFlags) {
            if (flag.equals(Boolean.toString(canOrder))) {
                return;
            }
        }

        Future<String> future = executor.submit(new MCRFixedUserCallable<>(() -> {
            object.getService().removeFlags(FLAG_CAN_ORDER);
            object.getService().addFlag(FLAG_CAN_ORDER, Boolean.toString(canOrder));
            MCRMetadataManager.update(object);
            return FLAG_CAN_ORDER;
        }, MCRSystemUserInformation.getSuperUserInstance()));

        try {
            future.get();
        } catch (InterruptedException|ExecutionException e) {
            throw new MCRException("Error while setting canOrder flag for object " + id, e);
        }
    }

    public static Boolean getCanOrder(String idObj) {
        return getCanOrder(MCRObjectID.getInstance(idObj));
    }

    public static Boolean getCanOrder(MCRObjectID idObj) {
        MCRObject object = MCRMetadataManager.retrieveMCRObject(idObj);

        ArrayList<String> existingFlags = object.getService().getFlags(FLAG_CAN_ORDER);
        if (existingFlags.size() > 1) {
            throw new IllegalStateException(
                "The object " + idObj + " has more than one flag of type " + FLAG_CAN_ORDER + "!");
        }
        for (String flag : existingFlags) {
            return Boolean.parseBoolean(flag);
        }
        return false;
    }
}
