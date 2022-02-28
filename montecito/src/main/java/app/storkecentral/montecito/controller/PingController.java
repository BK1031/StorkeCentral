package app.storkecentral.montecito.controller;

import app.storkecentral.montecito.Config;
import app.storkecentral.montecito.model.StandardResponse;

import static spark.Spark.get;

public class PingController {

    public PingController() {
        ping();
    }

    public void ping() {
        get("/montecito/ping", (req, res) -> {
            res.body(StandardResponse.success("{\"message\": \"" + "Montecito v" + Config.VERSION + " is online!" + "\"}", "Montecito v" + Config.VERSION));
            return res;
        });
    }
}
