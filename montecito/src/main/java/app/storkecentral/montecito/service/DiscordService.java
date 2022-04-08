package app.storkecentral.montecito.service;

import app.storkecentral.montecito.Config;
import com.google.api.client.util.DateTime;
import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.JDABuilder;
import net.dv8tion.jda.api.entities.Activity;
import spark.Request;
import spark.Response;

import javax.security.auth.login.LoginException;
import java.util.Date;
import java.util.UUID;

public class DiscordService {

    public static JDA client;

    public static void connect() {
        try {
            JDABuilder builder = JDABuilder.createDefault(Config.DISCORD_TOKEN);
            builder.setActivity(Activity.playing("with my tower"));
            client = builder.build();
            client.awaitReady();
            client.getGuildById(Config.DISCORD_GUILD).getTextChannelById(Config.DISCORD_CHANNEL).sendMessage(":white_check_mark: Montecito v" + Config.VERSION + " online! `[ENV = " + Config.ENV + "]`").queue();
        } catch (InterruptedException | LoginException e) {
            e.printStackTrace();
        }
    }

    public static void logRequest(UUID uuid, Request request, Response response) {
        String userID = AuthService.decodeUserToken(request);
        if (response.status() == 200) {
            client.getGuildById(Config.DISCORD_GUILD).getTextChannelById(Config.DISCORD_CHANNEL).sendMessage(":green_circle:   `STATUS 200`\n" +
                    "```\n" +
                    uuid + "\n" +
                    "\n" +
                    new Date() + "\n" +
                    "[" + request.requestMethod() + "] " + request.url() + "\n" +
                    "User \"" + userID + "\" [" + request.ip() + "]\n" +
                    "```\n").queue();
        }
        else {
            client.getGuildById(Config.DISCORD_GUILD).getTextChannelById(Config.DISCORD_CHANNEL).sendMessage(":red_circle:   `STATUS " + response.status() + "`\n" +
                    "```\n" +
                    uuid + "\n" +
                    "\n" +
                    new Date() + "\n" +
                    "[" + request.requestMethod() + "] " + request.url() + "\n" +
                    "User \"" + userID + "\" [" + request.ip() + "]\n" +
                    "```\n").queue();
        }
    }

}
