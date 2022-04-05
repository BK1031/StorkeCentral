package app.storkecentral.montecito;

import static spark.Spark.*;

import app.storkecentral.montecito.controller.AuthController;
import app.storkecentral.montecito.controller.PingController;
import app.storkecentral.montecito.controller.RouteController;
import app.storkecentral.montecito.service.*;

import java.io.IOException;
import java.sql.SQLException;

public class Application {

    public static void main(String[] args) throws IOException {
        port(Config.PORT);
        init();
        FirebaseService.initialize();
        DiscordService.connect();
        DatabaseService.connect();
        try {
            MigrationService.v1(DatabaseService.db);
            AuthService.getAllTokens();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        RinconService.register();
        PingController pingController = new PingController();
        AuthController authController = new AuthController();
        RouteController routeController = new RouteController();
    }
}
