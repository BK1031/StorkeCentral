package app.storkecentral.montecito.model;

import app.storkecentral.montecito.Config;

import java.util.Date;

public class StandardResponse {

    public static String success(String data, String service) {
        return "{" +
                "\"status\":\"" + "SUCCESS" + "\"," +
                "\"gateway\":\"" + "Montecito v" + Config.VERSION + "\"," +
                "\"service\":\"" + service + "\"," +
                "\"date\":\"" + new Date().toString() + "\"," +
                "\"data\":" + data +
                "}";
    }

    public static String error(String data, String service) {
        return "{" +
                "\"status\":\"" + "ERROR" + "\"," +
                "\"gateway\":\"" + "Montecito v" + Config.VERSION + "\"," +
                "\"service\":\"" + service + "\"," +
                "\"date\":\"" + new Date().toString() + "\"," +
                "\"data\":" + data +
                "}";
    }
}
