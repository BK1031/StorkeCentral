package app.storkecentral.montecito.controller;

import app.storkecentral.montecito.Config;
import app.storkecentral.montecito.model.Service;
import app.storkecentral.montecito.model.StandardResponse;
import app.storkecentral.montecito.service.AuthService;
import app.storkecentral.montecito.service.DiscordService;
import app.storkecentral.montecito.service.RinconService;
import app.storkecentral.montecito.service.RouteService;
import com.google.api.client.http.*;
import com.google.api.client.http.javanet.NetHttpTransport;

import java.net.ConnectException;
import java.util.UUID;

import static spark.Spark.*;

public class RouteController {

    public RouteController() {
        handleCors();
        beforeFilters();
        afterFilters();
        proxyGet();
        proxyPost();
        proxyPut();
        proxyDelete();
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
                halt(401, StandardResponse.error("{\"message\": \"" + "Invalid/missing authentication key" + "\"}", "Montecito v" + Config.VERSION));
            }
            AuthService.decodeUserToken(request);
        });
    }

    public void afterFilters() {
        after((request, response) -> {
            RouteService.setCorsHeaders(request, response);
            response.header("Server", "Montecito Gateway v" + Config.VERSION + " (Jetty)");
            RouteService.postflightLogging(request, response);
        });
    }

    public void proxyGet() {
        get("*", (request, response) -> {
            UUID uuid = UUID.randomUUID();
            response.header("Request-ID", uuid.toString());
            System.out.println("GATEWAY REQUEST ID: " + uuid);
            Service service = RouteService.matchRoute(request, response, uuid.toString());
            if (service.getName() != null) {
                System.out.println("PROXIED TO: (" + service.getId() + ") " + service.getName());
                try {
                    HttpRequestFactory requestFactory = new NetHttpTransport().createRequestFactory();
                    HttpRequest proxyRequest = requestFactory.buildGetRequest(
                        new GenericUrl(service.getUrl() + request.uri())
                    );
                    HttpHeaders headers = new HttpHeaders();
                    for (String h : request.headers()) {
                        if (!h.equals("Content-Type") && !h.equals("Content-Length") && !h.equals("Connection") && !h.equals("Host")) {
                            headers.set(h, request.headers(h));
                        }
                    }
                    headers.set("Request-ID", uuid.toString());
                    proxyRequest.setHeaders(headers);
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
                response.status(500);
                response.body(StandardResponse.error("{\"message\": \"" + "No service found to handle: " + request.uri() + "\"}", "Rincon v" + RinconService.service.getVersion()));
            }
            DiscordService.logRequest(uuid, request, response);
            return response;
        });
    }

    public void proxyPost() {
        post("*", (request, response) -> {
            UUID uuid = UUID.randomUUID();
            response.header("Request-ID", uuid.toString());
            System.out.println("GATEWAY REQUEST ID: " + uuid);
            Service service = RouteService.matchRoute(request, response, uuid.toString());
            if (service.getName() != null) {
                System.out.println("PROXIED TO: (" + service.getId() + ") " + service.getName());
                try {
                    HttpRequestFactory requestFactory = new NetHttpTransport().createRequestFactory();
                    HttpRequest proxyRequest = requestFactory.buildPostRequest(
                        new GenericUrl(service.getUrl() + request.uri()),
                        ByteArrayContent.fromString("application/json", request.body())
                    );
                    HttpHeaders headers = new HttpHeaders();
                    for (String h : request.headers()) {
                        if (!h.equals("Content-Type") && !h.equals("Content-Length") && !h.equals("Connection") && !h.equals("Host")) {
                            headers.set(h, request.headers(h));
                        }
                    }
                    headers.set("Request-ID", uuid.toString());
                    proxyRequest.setHeaders(headers);
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
                response.status(500);
                response.body(StandardResponse.error("{\"message\": \"" + "No service found to handle: " + request.uri() + "\"}", "Rincon v" + RinconService.service.getVersion()));
            }
            DiscordService.logRequest(uuid, request, response);
            return response;
        });
    }

    public void proxyPut() {
        put("*", (request, response) -> {
            UUID uuid = UUID.randomUUID();
            response.header("Request-ID", uuid.toString());
            System.out.println("GATEWAY REQUEST ID: " + uuid);
            Service service = RouteService.matchRoute(request, response, uuid.toString());
            if (service.getName() != null) {
                System.out.println("PROXIED TO: (" + service.getId() + ") " + service.getName());
                try {
                    HttpRequestFactory requestFactory = new NetHttpTransport().createRequestFactory();
                    HttpRequest proxyRequest = requestFactory.buildPutRequest(
                            new GenericUrl(service.getUrl() + request.uri()),
                            ByteArrayContent.fromString("application/json", request.body())
                    );
                    HttpHeaders headers = new HttpHeaders();
                    for (String h : request.headers()) {
                        if (!h.equals("Content-Type") && !h.equals("Content-Length") && !h.equals("Connection") && !h.equals("Host")) {
                            headers.set(h, request.headers(h));
                        }
                    }
                    headers.set("Request-ID", uuid.toString());
                    proxyRequest.setHeaders(headers);
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
                response.status(500);
                response.body(StandardResponse.error("{\"message\": \"" + "No service found to handle: " + request.uri() + "\"}", "Rincon v" + RinconService.service.getVersion()));
            }
            DiscordService.logRequest(uuid, request, response);
            return response;
        });
    }

    public void proxyDelete() {
        delete("*", (request, response) -> {
            UUID uuid = UUID.randomUUID();
            response.header("Request-ID", uuid.toString());
            System.out.println("GATEWAY REQUEST ID: " + uuid);
            Service service = RouteService.matchRoute(request, response, uuid.toString());
            if (service.getName() != null) {
                System.out.println("PROXIED TO: (" + service.getId() + ") " + service.getName());
                try {
                    HttpRequestFactory requestFactory = new NetHttpTransport().createRequestFactory();
                    HttpRequest proxyRequest = requestFactory.buildDeleteRequest(
                        new GenericUrl(service.getUrl() + request.uri())
                    );
                    HttpHeaders headers = new HttpHeaders();
                    for (String h : request.headers()) {
                        if (!h.equals("Content-Type") && !h.equals("Content-Length") && !h.equals("Connection") && !h.equals("Host")) {
                            headers.set(h, request.headers(h));
                        }
                    }
                    headers.set("Request-ID", uuid.toString());
                    proxyRequest.setHeaders(headers);
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
                response.status(500);
                response.body(StandardResponse.error("{\"message\": \"" + "No service found to handle: " + request.uri() + "\"}", "Rincon v" + RinconService.service.getVersion()));
            }
            DiscordService.logRequest(uuid, request, response);
            return response;
        });
    }
}
