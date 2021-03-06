package app.storkecentral.montecito.service;

import app.storkecentral.montecito.Config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DatabaseService {

    public static Connection db;

    static int retries = 0;

    public static void connect() {
        Connection connection = null;
        try {
            Properties props = new Properties();
            props.setProperty("user", Config.USER);
            props.setProperty("password", Config.PASSWORD);
            connection = DriverManager.getConnection(Config.URL, props);
            System.out.println("Connected to the PostgreSQL server successfully.");
            System.out.println(Config.URL);
            db = connection;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            if (retries < 15) {
                retries++;
                System.out.println("Retrying connection attempt in 5s...");
                try {
                    Thread.sleep(5000);
                } catch (InterruptedException ex) {
                    ex.printStackTrace();
                }
                connect();
            }
            else {
                System.out.println("Failed to connect after 15 attempts, terminating program...");
                System.exit(100);
            }
        }
    }

}
