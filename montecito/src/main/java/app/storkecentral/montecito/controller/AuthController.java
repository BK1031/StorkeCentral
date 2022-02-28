package app.storkecentral.montecito.controller;

import app.storkecentral.montecito.Config;
import app.storkecentral.montecito.model.StandardResponse;
import app.storkecentral.montecito.service.AuthService;

import static spark.Spark.get;

public class AuthController {

    public AuthController() {
        refreshTokens();
    }

    public void refreshTokens() {
        get("/montecito/refresh-tokens", (req, res) -> {
            AuthService.getAllTokens();
            res.body(StandardResponse.success("{\"message\": \"" + "API Tokens have been refreshed!" + "\"}", "Montecito v" + Config.VERSION));
            return res;
        });
    }

}
