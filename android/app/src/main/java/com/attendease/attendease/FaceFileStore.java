package com.attendease.attendease;

import android.content.Context;

import java.io.File;

final class FaceFileStore {
    private FaceFileStore() {}

    static File getFaceDirectory(Context context) {
        File directory = new File(context.getFilesDir(), "registered_faces");
        if (!directory.exists()) {
            directory.mkdirs();
        }
        return directory;
    }

    static File getFaceFile(Context context, String userKey) {
        String safeKey = userKey.replaceAll("[^a-zA-Z0-9._-]", "_");
        return new File(getFaceDirectory(context), safeKey + ".png");
    }
}
