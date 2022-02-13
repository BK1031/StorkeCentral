package app.storkecentral.montecito;

import static spark.Spark.*;

import app.storkecentral.montecito.controller.RouteController;
import app.storkecentral.montecito.service.DatabaseService;
import app.storkecentral.montecito.service.DiscordService;
import app.storkecentral.montecito.service.RouteService;

import javax.security.auth.login.LoginException;

public class Application {

    public static void main(String[] args) {
        port(Config.PORT);
        init();
        DiscordService.connect();
//        DatabaseService.connect();

        RouteController routeController = new RouteController();
    }
}
