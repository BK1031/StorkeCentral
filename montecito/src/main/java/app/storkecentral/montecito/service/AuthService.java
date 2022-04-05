package app.storkecentral.montecito.service;

import app.storkecentral.montecito.model.Token;
import spark.Request;
import spark.Response;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class AuthService {

    static public List<Token> tokenList = new ArrayList<>();

    public static void getAllTokens() throws SQLException {
        tokenList.clear();
        System.out.println("Fetching latest token list...");
        String sql = "SELECT * FROM \"api_key\"";
        ResultSet rs = DatabaseService.db.createStatement().executeQuery(sql);
        while(rs.next()) {
            Token token = new Token(rs.getString("id"), rs.getString("agent"), rs.getTimestamp("created"));
            System.out.println(token);
            tokenList.add(token);
        }
        rs.close();
        System.out.println("Refreshed token list!");
    }

    public static boolean checkAuth(Request request) {
        if (request.requestMethod().equals("OPTIONS")) return true;
        if (request.url().contains("ping")) return true;
        if (request.headers("SC_API_TOKEN") != null) {
            String key = request.headers("SC_API_TOKEN").replaceAll(" ", "");
            System.out.println("API TOKEN: " + key);
            for (Token token : tokenList) {
                if (token.getKey().equals(key)) return true;
            }
        }
        return false;
    }

    public static boolean checkUserToken(Request request) {
        if (request.headers("FB_USER_TOKEN") != null) {

        }
        return false;
    }

}
