package de.vzg.leopoldina;

import java.io.IOException;
import java.io.OutputStream;
import java.io.StringReader;
import java.io.StringWriter;
import java.text.MessageFormat;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.Locale;
import java.util.UUID;

import javax.imageio.ImageIO;
import javax.imageio.stream.ImageOutputStream;
import jakarta.servlet.http.HttpServletResponse;
import javax.sound.sampled.AudioFileFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;

import org.mycore.access.MCRAccessException;
import org.mycore.common.MCRException;
import org.mycore.common.MCRMailer;
import org.mycore.common.config.MCRConfiguration2;
import org.mycore.crypt.MCRCipherManager;
import org.mycore.crypt.MCRCryptKeyFileNotFoundException;
import org.mycore.crypt.MCRCryptKeyNoPermissionException;
import org.mycore.datamodel.metadata.MCRMetadataManager;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.frontend.MCRFrontendUtil;
import org.mycore.frontend.servlets.MCRServlet;
import org.mycore.frontend.servlets.MCRServletJob;
import org.mycore.services.i18n.MCRTranslation;

import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonWriter;

import net.logicsquad.nanocaptcha.audio.AudioCaptcha;
import net.logicsquad.nanocaptcha.image.ImageCaptcha;

public class LeopoldinaOrderServlet extends MCRServlet {

    public static final String CAN_ORDER_PARAM = "canOrder";
    public static final String USE_SET_ORDER_PRIV = "use-set-order";
    public static final String ACTION_PARAMETER = "action";
    public static final String INFO_OBJ_ID = "objID";
    public static final String OBJ_ID_PARAM = INFO_OBJ_ID;
    public static final String INFO_MAIL = "email";
    public static final String INFO_NAME = "name";
    public static final String INFO_ADDRESS = "address";
    public static final String INFO_COMMENT = "comment";
    public static final String INFO_MAILID = "mailid";

    public static final String INFO_AMOUNT = "amount";

    public static final String INFO_EXPIRES = "expires";
    public static final String MAIL_SENDER = MCRConfiguration2.getStringOrThrow("MCR.Mail.Sender");
    public static final String MAIL_LOCALE = MCRConfiguration2.getStringOrThrow("Leopoldina.Order.Mail.Locale");
    private static final String CAPTCHA_PARAM = "captcha";

    public static void order(MCRServletJob job) throws IOException {
        String objIdStr = job.getRequest().getParameter(OBJ_ID_PARAM);

        if (objIdStr == null) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing " + OBJ_ID_PARAM + " in request!");
            return;
        }

        String captcha = job.getRequest().getParameter(CAPTCHA_PARAM);
        if (captcha == null) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST,
                "Missing " + CAPTCHA_PARAM + " in request!");
            return;
        }

        String sessionCaptcha = (String) job.getRequest().getSession().getAttribute("leopoldina_captcha");
        String sessionCaptchaPlay = (String) job.getRequest().getSession().getAttribute("leopoldina_captcha_play");
        if (!captcha.equals(sessionCaptcha) && !captcha.equals(sessionCaptchaPlay)) {
            job.getResponse().sendError(422, "Captcha is not valid!");
            return;
        }

        // delete captcha from session
        job.getRequest().getSession().removeAttribute("leopoldina_captcha");
        job.getRequest().getSession().removeAttribute("leopoldina_captcha_play");

        MCRObjectID objId = MCRObjectID.getInstance(objIdStr);
        if (!MCRMetadataManager.exists(objId)) {
            job.getResponse().sendError(HttpServletResponse.SC_NOT_FOUND, "Object " + objId + " does not exist!");
            return;
        }

        String email = job.getRequest().getParameter(INFO_MAIL);
        if (email == null || email.isEmpty()) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing email parameter!");
            return;
        }

        String name = job.getRequest().getParameter(INFO_NAME);
        if (name == null || name.isEmpty()) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing name parameter!");
            return;
        }

        String address = job.getRequest().getParameter(INFO_ADDRESS);
        if (address == null || address.isEmpty()) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing address parameter!");
            return;
        }

        String comment = job.getRequest().getParameter(INFO_COMMENT);
        if (comment == null || comment.isEmpty()) {
           comment = MCRTranslation.translate("component.leopoldina.order.defaultComment");
        }

        String amountStr = job.getRequest().getParameter(INFO_AMOUNT);
        if (amountStr == null || amountStr.isEmpty()) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing amount parameter!");
            return;
        }
        try {
            int amount = Integer.parseInt(amountStr);
            if(amount< 1) {
                job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Amount must be greater than 0!");
                return;
            } else if(amount > 100) {
                job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Amount must be less than 100!");
                return;
            }
        } catch (NumberFormatException e) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Amount is not a number!");
            return;
        }

        StringWriter out = new StringWriter();

        try (JsonWriter writer = new JsonWriter(out)) {
            writer.beginObject();
            writer.name(INFO_OBJ_ID).value(objId.toString());
            writer.name(INFO_MAIL).value(email);
            writer.name(INFO_NAME).value(name);
            writer.name(INFO_ADDRESS).value(address);
            writer.name(INFO_COMMENT).value(comment);
            writer.name(INFO_MAILID).value(UUID.randomUUID().toString());
            writer.name(INFO_AMOUNT).value(amountStr);
            writer.name(INFO_EXPIRES).value(Instant.now().plus(2, ChronoUnit.HOURS).toEpochMilli());
            writer.endObject();
        }

        String info = out.getBuffer().toString();
        String infoEncrypt = null;
        try {
            infoEncrypt = MCRCipherManager.getCipher("mail").encrypt(info);
            byte[] bytes = Base64.getDecoder().decode(infoEncrypt);
            infoEncrypt = Base64.getUrlEncoder().encodeToString(bytes);
        } catch (MCRCryptKeyNoPermissionException e) {
            job.getResponse().sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not encrypt order info!");
            return;
        }
        String confirmLink
            = MCRFrontendUtil.getBaseURL() + "servlets/LeopoldinaOrderServlet?action=order-confirm&info=" + infoEncrypt;

        String objectUrl = MCRFrontendUtil.getBaseURL() + "receive/" + objId;

        String mailText
            = MCRTranslation.translate("leopoldina.order.mailto.body", objectUrl, name, address, amountStr, comment,
                confirmLink);

        MCRMailer.send(MAIL_SENDER, email, MCRTranslation.translate("leopoldina.order.mailto.subject", objIdStr),
            mailText);

        job.getResponse().setStatus(HttpServletResponse.SC_OK);
        job.getResponse().getWriter().write("OK");
    }

    private static void changeOrderableStatus(MCRServletJob job) throws IOException, MCRAccessException {
        String objIdStr = job.getRequest().getParameter(OBJ_ID_PARAM);
        String canOrderStr = job.getRequest().getParameter(CAN_ORDER_PARAM);

        if (objIdStr == null) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing " + OBJ_ID_PARAM + " in request!");
            return;
        }

        if (canOrderStr == null) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST,
                "Missing " + CAN_ORDER_PARAM + " in request!");
            return;
        }

        if (!MCRObjectID.isValid(objIdStr)) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "The id " + objIdStr + " is not valid!");
            return;
        }

        boolean canOrder = Boolean.parseBoolean(canOrderStr);

        MCRObjectID objectID = MCRObjectID.getInstance(objIdStr);
        if (!MCRMetadataManager.exists(objectID)) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST,
                "The object " + objIdStr + " does not exist!");
            return;
        }

        if (!LeopoldinaOrderUtil.changeOrderableAllowed(objectID)) {
            job.getResponse().sendError(HttpServletResponse.SC_FORBIDDEN,
                "You dont have the right to mark the document as orderable!");
            return;
        }

        LeopoldinaCanOrderDAO.setCanOrder(objectID, canOrder);
        job.getResponse().setStatus(HttpServletResponse.SC_OK);
        job.getResponse().sendRedirect(MCRFrontendUtil.getBaseURL() + "receive/" + objectID
            + "?XSL.Status.Style=success&XSL.Status.Message=mir.editstatus.success&refresh=" + UUID.randomUUID());
    }

    @Override
    protected void doGetPost(MCRServletJob job) throws Exception {
        String action = job.getRequest().getParameter(ACTION_PARAMETER);

        if (action == null) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing action parameter!");
            return;
        }
        switch (action) {
        case "change":
            changeOrderableStatus(job);
            break;
        case "order":
            order(job);
            break;
        case "order-confirm":
            orderConfirm(job);
            break;
        case "captcha":
            captcha(job);
            break;
        case "captcha-play":
            captchaPlay(job);
            break;
        default:
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "Unknown action: " + action);
        }

    }

    private void captchaPlay(MCRServletJob job) throws IOException {
        AudioCaptcha ac = new AudioCaptcha.Builder().addContent().build();
        String content = ac.getContent();
        job.getRequest().getSession().setAttribute("leopoldina_captcha_play", content);
        job.getResponse().setContentType("audio/wav");
        try (OutputStream out = job.getResponse().getOutputStream();
            AudioInputStream ais = ac.getAudio().getAudioInputStream()) {
            AudioSystem.write(ais, AudioFileFormat.Type.WAVE, out);
        }
    }

    private void captcha(MCRServletJob job) throws IOException {
        job.getResponse().setContentType("image/png");
        ImageCaptcha imageCaptcha = new ImageCaptcha.Builder(200, 50).addContent().build();
        String captchaText = imageCaptcha.getContent();
        job.getRequest().getSession().setAttribute("leopoldina_captcha", captchaText);
        job.getResponse().setContentType("image/png");
        try (ImageOutputStream ios = ImageIO.createImageOutputStream(job.getResponse().getOutputStream())) {
            ImageIO.write(imageCaptcha.getImage(), "png", ios);
        }
    }

    private void orderConfirm(MCRServletJob job) throws IOException {
        String info = job.getRequest().getParameter("info");

        String infoDecrypt;
        try {
            byte[] bytes = Base64.getUrlDecoder().decode(info);
            info = Base64.getEncoder().encodeToString(bytes);
            infoDecrypt = MCRCipherManager.getCipher("mail").decrypt(info);
        } catch (MCRCryptKeyNoPermissionException | MCRCryptKeyFileNotFoundException e) {
            throw new MCRException(e);
        }

        String objIdStr = null, email = null, name = null, address = null, comment = null, mailId = null, amount = null;

        try (JsonReader reader = new JsonReader(new StringReader(infoDecrypt))) {
            reader.beginObject();
            while (reader.hasNext()) {
                String s = reader.nextName();

                switch (s) {
                case INFO_OBJ_ID:
                    objIdStr = reader.nextString();
                    break;
                case INFO_MAIL:
                    email = reader.nextString();
                    break;
                case INFO_NAME:
                    name = reader.nextString();
                    break;
                case INFO_ADDRESS:
                    address = reader.nextString();
                    break;
                case INFO_COMMENT:
                    comment = reader.nextString();
                    break;
                case INFO_MAILID:
                    mailId = reader.nextString();
                    break;
                case INFO_EXPIRES:
                    long expires = reader.nextLong();
                    if (expires < Instant.now().toEpochMilli()) {
                        job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST,
                            MCRTranslation.translate("leopoldina.order.mailto.expired"));
                        return;
                    }
                    break;
                case INFO_AMOUNT:
                    amount = reader.nextString();
                    break;
                }
            }
            reader.endObject();
        } catch (IOException e) {
            throw new MCRException("Error while reading order info!", e);
        }

        if (objIdStr == null || email == null || name == null || address == null || comment == null || mailId == null
            || amount == null) {
            throw new MCRException("Error while reading order info! (Missing values)");
        }

        MCRObjectID objId = MCRObjectID.getInstance(objIdStr);
        if (!MCRMetadataManager.exists(objId)) {
            throw new MCRException("The object " + objIdStr + " does not exist!");
        }

        if (LeopoldinaOrderUtil.wasMailSend(mailId)) {
            job.getResponse().sendError(HttpServletResponse.SC_BAD_REQUEST, "The order was already confirmed!");
            return;
        }

        String targetMail = LeopoldinaOrderUtil.getTargetMail(objIdStr);

        String objectUrl = MCRFrontendUtil.getBaseURL() + "receive/" + objIdStr;

        Locale locale = MCRTranslation.getLocale(MAIL_LOCALE);
        String mailBody
            = translate("leopoldina.order.mailto.body2", locale, objectUrl, email, name, address, amount,
                comment);

        MCRMailer.send(MAIL_SENDER, targetMail, translate("leopoldina.order.mailto.subject", locale, objIdStr),
            mailBody);
        LeopoldinaOrderUtil.markMailSend(mailId);
        job.getResponse().sendRedirect(MCRFrontendUtil.getBaseURL() + "receive/" + objIdStr
            + "?XSL.Status.Style=success&XSL.Status.Message=mir.order.success&refresh=" + UUID.randomUUID());
    }

    public static String translate(String key, Locale locale, Object... args) {
        String translation = MCRTranslation.translate(key, locale);
        return new MessageFormat(translation, locale).format(args);
    }

}
