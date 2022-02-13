package app.storkecentral.montecito.model;

import java.time.ZonedDateTime;
import java.util.Date;

public class Token {
    private String key;
    private Date created;

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
}
