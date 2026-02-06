package de.vzg.leopoldina;

import org.junit.Assert;
import org.junit.Test;
import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRException;
import org.mycore.common.MCRSessionMgr;
import org.mycore.common.MCRStoreTestCase;
import org.mycore.common.MCRSystemUserInformation;
import org.mycore.common.MCRTestCase;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObject;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.util.concurrent.MCRFixedUserCallable;

import java.util.Map;

public class LeopoldinaCanOrderDAOTest extends MCRStoreTestCase {

    private void createObject(MCRObjectID id) throws MCRAccessException {
        MCRObject object = new MCRObject();
        object.setSchema("noSchema");
        object.setId(id);
        MCRMetadataManager.create(object);

    }

    @Test
    public void getCanOrder() throws MCRAccessException, InterruptedException {
        MCRObjectID test_id_00000001 = MCRObjectID.getInstance("test_test_00000001");
        MCRObjectID test_id_00000002 = MCRObjectID.getInstance("test_test_00000002");
        MCRObjectID test_id_00000003 = MCRObjectID.getInstance("test_test_00000003");

        Thread t = new Thread(() -> {
            try {
                new MCRFixedUserCallable<>(() -> {
                    createObject(test_id_00000001);
                    createObject(test_id_00000002);
                    createObject(test_id_00000003);
                    return null;
                }, MCRSystemUserInformation.getSuperUserInstance()).call();
            } catch (Exception e) {
                throw new MCRException(e);
            }

        });
        t.start();
        t.join();


        Assert.assertFalse("The initial order state should be false",
            LeopoldinaCanOrderDAO.getCanOrder(test_id_00000001));
        Assert.assertFalse("The initial order state should be false",
            LeopoldinaCanOrderDAO.getCanOrder(test_id_00000002));
        Assert.assertFalse("The initial order state should be false",
            LeopoldinaCanOrderDAO.getCanOrder(test_id_00000003));

        LeopoldinaCanOrderDAO.setCanOrder(test_id_00000001, true);
        LeopoldinaCanOrderDAO.setCanOrder(test_id_00000002, false);

        Assert.assertTrue("You should be able to order the id", LeopoldinaCanOrderDAO.getCanOrder(test_id_00000001));
        Assert.assertFalse("You should not be able to order the id",
            LeopoldinaCanOrderDAO.getCanOrder(test_id_00000002));
        Assert.assertFalse("The initial order state should be false",
            LeopoldinaCanOrderDAO.getCanOrder(test_id_00000003));

        LeopoldinaCanOrderDAO.setCanOrder(test_id_00000003, true);
        LeopoldinaCanOrderDAO.setCanOrder(test_id_00000003, false);

        Assert.assertTrue("You should be able to order the id", LeopoldinaCanOrderDAO.getCanOrder(test_id_00000001));
        Assert.assertFalse("You should not be able to order the id",
            LeopoldinaCanOrderDAO.getCanOrder(test_id_00000002));
        Assert.assertFalse("You should not be able to order the id",
            LeopoldinaCanOrderDAO.getCanOrder(test_id_00000003));

        LeopoldinaCanOrderDAO.setCanOrder(test_id_00000002, true);
        Assert.assertTrue("You should be able to order the id", LeopoldinaCanOrderDAO.getCanOrder(test_id_00000001));
        Assert.assertTrue("You should be able to order the id", LeopoldinaCanOrderDAO.getCanOrder(test_id_00000002));
        Assert.assertFalse("You should not be able to order the id",
            LeopoldinaCanOrderDAO.getCanOrder(test_id_00000003));

    }

    @Override
    protected Map<String, String> getTestProperties() {
        Map<String, String> testProperties = super.getTestProperties();
        testProperties.put("MCR.Metadata.Type.test", Boolean.TRUE.toString());
        testProperties.put("MCR.Metadata.Type.junit", Boolean.TRUE.toString());
        testProperties.put("MCR.Category.LinkService",
            "org.mycore.datamodel.classifications2.impl.MCRCategLinkServiceImpl");
        testProperties.put("MCR.Category.DAO", "org.mycore.datamodel.classifications2.impl.MCRCategoryDAOImpl");
        testProperties.put("MCR.EventHandler.MCRObject.025.Class", "");
        testProperties.put("MCR.EventHandler.MCRObject.017.Class", "");

        return testProperties;
    }
}
