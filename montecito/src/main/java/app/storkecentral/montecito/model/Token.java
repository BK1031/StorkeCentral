package app.storkecentral.montecito.model;

import java.time.ZonedDateTime;
import java.util.Date;

public class Token {
    private String key;
    private String agent;
    private Date created;

    public Token(String key, String agent, Date created) {
        this.key = key;
        this.agent = agent;
        this.created = created;
    }

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }

    public Date getCreated() {
        return created;
    }

    public void setCreated(Date created) {
        this.created = created;
    }

    public String getAgent() {
        return agent;
    }

    public void setAgent(String agent) {
        this.agent = agent;
    }
}
