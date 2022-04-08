package app.storkecentral.montecito.service;

import app.storkecentral.montecito.Config;
import app.storkecentral.montecito.model.Service;
import com.google.api.client.http.*;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.gson.Gson;

import java.io.IOException;
import java.net.ConnectException;
import java.util.HashMap;
import java.util.Map;

public class RinconService {

    public static Service service = new Service();

    static Gson gson = new Gson();

    public static void register() {
        try {
            Service montecito = new Service();
            montecito.setName("Montecito");
            montecito.setUrl("http://localhost:" + Config.PORT);
            montecito.setPort(Config.PORT);
            montecito.setStatusEmail(Config.STATUS_EMAIL);
            montecito.setVersion(Config.VERSION);

            HttpRequestFactory requestFactory = new NetHttpTransport().createRequestFactory();
            HttpRequest request = requestFactory.buildPostRequest(
                    new GenericUrl("http://localhost:" + Config.RINCON_PORT + "/services"),
                    ByteArrayContent.fromString("application/json", gson.toJson(montecito))
            );
            HttpResponse response = request.execute();
            if (response.getStatusCode() == 200) {
                System.out.println("Registered Montecito w/ Rincon!");
                registerRoutes();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void registerRoutes() {
        try {
            HttpRequestFactory requestFactory = new NetHttpTransport().createRequestFactory();
            HttpRequest request = requestFactory.buildPostRequest(
                    new GenericUrl("http://localhost:" + Config.RINCON_PORT + "/routes"),
                    ByteArrayContent.fromString("application/json", "{\n" +
                            "  \"route\": \"/montecito\",\n" +
                            "  \"service_name\": \"montecito\"\n" +
                            "}")
            );
            HttpResponse response = request.execute();
            if (response.getStatusCode() == 200) {
                System.out.println("Registered routes w/ Rincon!");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
