package app.storkecentral.montecito.service;

import spark.Request;
import spark.Response;

import java.util.Date;

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

    public static void setCorsHeaders(Request request, Response response) {
        response.header("Access-Control-Allow-Origin", "*");
        response.header("Access-Control-Allow-Headers", "*");
        response.header("Access-Control-Allow-Methods", "GET,PUT,POST,DELETE,OPTIONS");
        response.header("Access-Control-Allow-Credentials", "true");
        response.type("application/json");
    }

    public static void preflightLogging(Request request, Response response) {
        System.out.println("-------------------------------------------------------------------");
        System.out.println(new Date());
        System.out.println("REQUESTED ROUTE: " + request.url() + " [" + request.requestMethod() + "]");
        System.out.println("REQUEST BODY: " + request.body());
        System.out.println("REQUEST ORIGIN: " + request.host() + " [" + request.ip() + "]");
    }

    public static void postflightLogging(Request request, Response response) {
        System.out.println("RESPONSE CODE: " + response.status());
        System.out.println("RESPONSE BODY: " + response.body());
        System.out.println("-------------------------------------------------------------------");
    }
}
