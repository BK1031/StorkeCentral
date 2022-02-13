package app.storkecentral.montecito;

public class Config {
    final public static String VERSION = "1.0.0";

    public static String ENV = System.getenv("ENV");
    public static int PORT = Integer.parseInt(System.getenv("PORT"));

    public static String DISCORD_TOKEN = System.getenv("DISCORD_TOKEN");
    public static String DISCORD_GUILD = System.getenv("DISCORD_GUILD");
    public static String DISCORD_CHANNEL = System.getenv("DISCORD_CHANNEL");

    public static String URL = System.getenv("JDBC");
    public static String USER = System.getenv("POSTGRES_USERNAME");
    public static String PASSWORD = System.getenv("POSTGRES_PASSWORD");
}
