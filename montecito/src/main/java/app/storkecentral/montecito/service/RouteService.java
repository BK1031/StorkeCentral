package app.storkecentral.montecito.service;

import spark.Request;
import spark.Response;

public class RouteService {

    public static Response handleCors(Request request, Response response) {
        String accessControlRequestHeaders = request.headers("Access-Control-Request-Headers");
        if (accessControlRequestHeaders != null) {
            response.header("Access-Control-Allow-Headers", accessControlRequestHeaders);
        }
        String accessControlRequestMethod = request.headers("Access-Control-Request-Method");
        if (accessControlRequestMethod != null) {
            response.header("Access-Control-Allow-Methods", accessControlRequestMethod);
        }
        response.status(200);
        response.body("OK");
        return response;
    }
}
