package app.storkecentral.montecito.service;

import app.storkecentral.montecito.model.Token;
import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
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
        System.out.println("Fetching latest api keys...");
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
        if (request.headers("SC-API-KEY") != null) {
            String key = request.headers("SC-API-KEY").replaceAll(" ", "");
            System.out.println("API KEY: " + key);
            for (Token token : tokenList) {
                if (token.getKey().equals(key)) return true;
            }
        }
        return false;
    }

    public static String decodeUserToken(Request request) {
        if (request.headers("Authorization") != null) {
            try {
                FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(request.headers("Authorization").split("Bearer ")[1]);
                System.out.println("DECODED TOKEN USER \"" + decodedToken.getUid() + "\"");
                return decodedToken.getUid();
            } catch (FirebaseAuthException e) {
                e.printStackTrace();
            }
        }
        return "null";
    }

}
