package app.storkecentral.montecito.service;

import app.storkecentral.montecito.Config;
import app.storkecentral.montecito.model.Service;
import com.google.api.client.http.*;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.gson.Gson;
import spark.Request;
import spark.Response;

import java.io.IOException;
import java.net.ConnectException;
import java.util.Date;


public class RouteService {

    static Gson gson = new Gson();

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
    }

    public static Service matchRoute(Request request) {
        String queryRoute = request.uri().replaceFirst("/", "").replaceAll("/", "-");
        System.out.println(queryRoute);
        Service service = new Service();
        try {
            HttpRequestFactory requestFactory = new NetHttpTransport().createRequestFactory();
            HttpRequest rinconRequest = requestFactory.buildGetRequest(new GenericUrl("http://localhost:" + Config.RINCON_PORT + "/routes/match/" + queryRoute));
            HttpResponse rinconResponse = rinconRequest.execute();
            if (rinconResponse.getStatusCode() == 200) {
                service = gson.fromJson(rinconResponse.parseAsString(), Service.class);
            }
            else {
                System.out.println("Route Matching Error!");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return service;
    }
}
