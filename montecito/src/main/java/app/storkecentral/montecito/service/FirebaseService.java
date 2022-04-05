package app.storkecentral.montecito.service;

import app.storkecentral.montecito.Application;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;

public class FirebaseService {

    public static FirebaseApp app;

    public static void initialize() throws IOException {
        // Firebase admin time
        try {
            InputStream serviceAccount = Application.class.getClassLoader().getResourceAsStream("serviceAccountKey.json");
            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .setProjectId("storke-central")
                    .setDatabaseUrl("https://pacific-esports-default-rtdb.firebaseio.com/")
                    .build();
            FirebaseApp.initializeApp(options);
        } catch (NullPointerException err) {
            FileInputStream serviceAccount = new FileInputStream("src/main/resources/serviceAccountKey.json");
            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .setProjectId("pacific-esports")
                    .setDatabaseUrl("https://pacific-esports-default-rtdb.firebaseio.com/")
                    .build();
            FirebaseApp.initializeApp(options);
        }
    }

}
