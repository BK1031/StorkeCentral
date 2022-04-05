package app.storkecentral.montecito.controller;

import app.storkecentral.montecito.Config;
import app.storkecentral.montecito.model.Service;
import app.storkecentral.montecito.model.StandardResponse;
import app.storkecentral.montecito.service.AuthService;
import app.storkecentral.montecito.service.RinconService;
import app.storkecentral.montecito.service.RouteService;
import com.google.api.client.http.*;
import com.google.api.client.http.javanet.NetHttpTransport;

import java.net.ConnectException;

import static spark.Spark.*;

public class RouteController {

    public RouteController() {
        handleCors();
        beforeFilters();
        afterFilters();
        proxyGet();
    }

    public void handleCors() {
        options("/*", (request, response) -> {
            return RouteService.handleCors(request, response);
        });
    }

    public void beforeFilters() {
        before((request, response) -> {
            RouteService.preflightLogging(request, response);
            if (!AuthService.checkAuth(request)) {
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

    public void proxyGet() {
        get("*", (request, response) -> {
            Service service = RouteService.matchRoute(request);
            if (service.getName() != null) {
                try {
                    HttpRequestFactory requestFactory = new NetHttpTransport().createRequestFactory();
                    HttpRequest proxyRequest = requestFactory.buildGetRequest(new GenericUrl(service.getUrl() + request.uri()));
                    HttpResponse proxyResponse = proxyRequest.execute();
                    if (proxyResponse.getStatusCode() == 200) {
                        response.status(200);
                        response.body(StandardResponse.success(proxyResponse.parseAsString(), service.getName() + " v" + service.getVersion()));
                    }
                    else {
                        response.status(proxyResponse.getStatusCode());
                        response.body(StandardResponse.error(proxyResponse.parseAsString(), service.getName() + " v" + service.getVersion()));
                    }
                } catch (HttpResponseException e) {
                    response.status(e.getStatusCode());
                    response.body(StandardResponse.error(e.getContent(), service.getName() + " v" + service.getVersion()));
                } catch (ConnectException e) {
                    response.status(503);
                    response.body(StandardResponse.error("{\"message\": \"Connection error! Is the service online?\"}", service.getName() + " v" + service.getVersion()));
                }
            }
            else {
                response.status(503);
                response.body(StandardResponse.error("{\"message\": \"" + "No service found to handle: " + request.uri() + "\"}", "Rincon v" + RinconService.service.getVersion()));
            }
            return response;
        });
    }
}
