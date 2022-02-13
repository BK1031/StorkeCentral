package app.storkecentral.montecito.service;

import app.storkecentral.montecito.Config;
import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.JDABuilder;
import net.dv8tion.jda.api.entities.Activity;

import javax.security.auth.login.LoginException;

public class DiscordService {

    public static JDA client;

    public static void connect() {
        try {
            JDABuilder builder = JDABuilder.createDefault(Config.DISCORD_TOKEN);
            builder.setActivity(Activity.playing("with my tower"));
            client = builder.build();
            client.awaitReady();
            client.getGuildById(Config.DISCORD_GUILD).getTextChannelById("940873583406751764").sendMessage(":white_check_mark: Montecito v" + Config.VERSION + " online!").queue();
        } catch (InterruptedException | LoginException e) {
            e.printStackTrace();
        }
    }

}
