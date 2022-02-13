package app.storkecentral.montecito.service;

import app.storkecentral.montecito.Config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DatabaseService {

    public static Connection db;

    public static void connect() {
        Connection connection = null;
        try {
            Properties props = new Properties();
            props.setProperty("user", Config.USER);
            props.setProperty("password", Config.PASSWORD);
            props.setProperty("autosave", "always");
            connection = DriverManager.getConnection(Config.URL, props);
            System.out.println("Connected to the PostgreSQL server successfully.");
            System.out.println(Config.URL);
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        db = connection;
    }

}
