package app.storkecentral.montecito.controller;

import app.storkecentral.montecito.service.RouteService;

import static spark.Spark.options;

public class RouteController {

    public RouteController() {

    }

    public void handleCors() {
        options("/*", (request, response) -> {
            return RouteService.handleCors(request, response);
        });
    }

}
