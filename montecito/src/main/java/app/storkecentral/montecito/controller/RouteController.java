package app.storkecentral.montecito.controller;

import app.storkecentral.montecito.Config;
import app.storkecentral.montecito.model.StandardResponse;
import app.storkecentral.montecito.service.AuthService;
import app.storkecentral.montecito.service.RouteService;

import static spark.Spark.*;

public class RouteController {

    public RouteController() {
        handleCors();
        beforeFilters();
        afterFilters();
    }

    public void handleCors() {
        options("/*", (request, response) -> {
            return RouteService.handleCors(request, response);
        });
    }

    public void beforeFilters() {
        before((request, response) -> {
            RouteService.preflightLogging(request, response);
            if (!AuthService.checkAuth(request, response)) {
                System.out.println("INVALID AUTHENTICATION!");
                response.type("application/json");
                halt(401, StandardResponse.error("{\"message\": \"" + "Invalid/missing authentication token" + "\"}", "Montecito v" + Config.VERSION));
            }
        });
    }

    public void afterFilters() {
        after((request, response) -> {
            RouteService.setCorsHeaders(request, response);
            RouteService.postflightLogging(request, response);
        });
    }
}
