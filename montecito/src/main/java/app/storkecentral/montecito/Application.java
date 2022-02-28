package app.storkecentral.montecito;

import static spark.Spark.*;

import app.storkecentral.montecito.controller.AuthController;
import app.storkecentral.montecito.controller.PingController;
import app.storkecentral.montecito.controller.RouteController;
import app.storkecentral.montecito.service.AuthService;
import app.storkecentral.montecito.service.DatabaseService;
import app.storkecentral.montecito.service.DiscordService;
import app.storkecentral.montecito.service.MigrationService;

import java.sql.SQLException;

public class Application {

    public static void main(String[] args) {
        port(Config.PORT);
        init();
        DiscordService.connect();
        DatabaseService.connect();
        try {
            MigrationService.v1(DatabaseService.db);
            AuthService.getAllTokens();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        RouteController routeController = new RouteController();
        AuthController authController = new AuthController();
        PingController pingController = new PingController();
    }
}
