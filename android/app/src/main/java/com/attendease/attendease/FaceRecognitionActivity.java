package com.attendease.attendease;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.media.Image;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.OptIn;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ExperimentalGetImage;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.content.ContextCompat;

import com.google.common.util.concurrent.ListenableFuture;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.face.Face;
import com.google.mlkit.vision.face.FaceDetection;
import com.google.mlkit.vision.face.FaceDetector;
import com.google.mlkit.vision.face.FaceDetectorOptions;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.concurrent.ExecutionException;

public class FaceRecognitionActivity extends AppCompatActivity {
    static final String EXTRA_MODE = "mode";
    static final String EXTRA_USER_KEY = "user_key";
    static final String EXTRA_MESSAGE = "message";
    static final String EXTRA_FACE_REGISTERED = "face_registered";
    static final String MODE_REGISTER = "register";
    static final String MODE_RECOGNIZE = "recognize";

    private static final float MATCH_THRESHOLD = 0.60f;

    private PreviewView previewView;
    private TextView titleView;
    private TextView statusView;
    private ProcessCameraProvider cameraProvider;
    private FaceDetector faceDetector;
    private TFLiteFaceRecognition recognizer;
    private String mode;
    private String userKey;
    private boolean busy;
    private boolean completed;

    private final ActivityResultLauncher<String> permissionLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.RequestPermission(),
                    granted -> {
                        if (granted) {
                            startCamera();
                        } else {
                            finishWithResult(Activity.RESULT_CANCELED, "Camera permission is required.", false);
                        }
                    });

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_face_recognition);

        previewView = findViewById(R.id.preview_view);
        titleView = findViewById(R.id.title_text);
        statusView = findViewById(R.id.status_text);
        Button cancelButton = findViewById(R.id.cancel_button);

        mode = getIntent().getStringExtra(EXTRA_MODE);
        userKey = getIntent().getStringExtra(EXTRA_USER_KEY);

        if (mode == null || userKey == null || userKey.trim().isEmpty()) {
            finishWithResult(Activity.RESULT_CANCELED, "Invalid face recognition request.", false);
            return;
        }

        titleView.setText(MODE_REGISTER.equals(mode) ? "Register Face" : "Verify Face");
        statusView.setText(
                MODE_REGISTER.equals(mode)
                        ? "Hold your face steady inside the frame."
                        : "Look at the camera to verify your attendance.");

        cancelButton.setOnClickListener(view -> finishWithResult(Activity.RESULT_CANCELED, "Operation cancelled.", false));

        FaceDetectorOptions options = new FaceDetectorOptions.Builder()
                .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
                .build();
        faceDetector = FaceDetection.getClient(options);

        try {
            recognizer = new TFLiteFaceRecognition(this);
        } catch (IOException exception) {
            finishWithResult(Activity.RESULT_CANCELED, "Failed to load MobileFaceNet model.", false);
            return;
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED) {
            startCamera();
        } else {
            permissionLauncher.launch(Manifest.permission.CAMERA);
        }
    }

    @Override
    protected void onDestroy() {
        if (cameraProvider != null) {
            cameraProvider.unbindAll();
        }
        if (faceDetector != null) {
            faceDetector.close();
        }
        super.onDestroy();
    }

    @OptIn(markerClass = ExperimentalGetImage.class)
    private void startCamera() {
        ListenableFuture<ProcessCameraProvider> providerFuture = ProcessCameraProvider.getInstance(this);
        providerFuture.addListener(() -> {
            try {
                cameraProvider = providerFuture.get();

                Preview preview = new Preview.Builder().build();
                preview.setSurfaceProvider(previewView.getSurfaceProvider());

                ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .build();

                imageAnalysis.setAnalyzer(ContextCompat.getMainExecutor(this), imageProxy -> {
                    if (busy || completed) {
                        imageProxy.close();
                        return;
                    }
                    Image mediaImage = imageProxy.getImage();
                    if (mediaImage == null || mediaImage.getFormat() != ImageFormat.YUV_420_888) {
                        imageProxy.close();
                        return;
                    }
                    busy = true;
                    detectFace(mediaImage, imageProxy);
                });

                CameraSelector cameraSelector = new CameraSelector.Builder()
                        .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                        .build();

                cameraProvider.unbindAll();
                cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageAnalysis);
            } catch (ExecutionException | InterruptedException exception) {
                finishWithResult(Activity.RESULT_CANCELED, "Unable to start the camera.", false);
            }
        }, ContextCompat.getMainExecutor(this));
    }

    private void detectFace(Image mediaImage, ImageProxy imageProxy) {
        InputImage image =
                InputImage.fromMediaImage(mediaImage, imageProxy.getImageInfo().getRotationDegrees());
        faceDetector.process(image)
                .addOnSuccessListener(faces -> {
                    if (faces.isEmpty()) {
                        statusView.setText("No face detected. Move closer and try again.");
                        busy = false;
                        imageProxy.close();
                        return;
                    }
                    Face face = faces.get(0);
                    Bitmap bitmap = cropFace(mediaImage, face.getBoundingBox());
                    imageProxy.close();
                    if (bitmap == null) {
                        statusView.setText("Unable to isolate face. Try again.");
                        busy = false;
                        return;
                    }
                    handleFace(bitmap);
                })
                .addOnFailureListener(error -> {
                    statusView.setText("Face detection failed. Try again.");
                    busy = false;
                    imageProxy.close();
                });
    }

    private void handleFace(Bitmap bitmap) {
        if (MODE_REGISTER.equals(mode)) {
            registerFace(bitmap);
        } else {
            recognizeFace(bitmap);
        }
    }

    private void registerFace(Bitmap bitmap) {
        File file = FaceFileStore.getFaceFile(this, userKey);
        try (FileOutputStream outputStream = new FileOutputStream(file)) {
            Bitmap normalized = Bitmap.createScaledBitmap(bitmap, 112, 112, false);
            normalized.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
            completed = true;
            finishWithResult(Activity.RESULT_OK, "Face registered successfully.", true);
        } catch (IOException exception) {
            statusView.setText("Unable to save face profile. Try again.");
            busy = false;
        }
    }

    private void recognizeFace(Bitmap bitmap) {
        File registeredFaceFile = FaceFileStore.getFaceFile(this, userKey);
        if (!registeredFaceFile.exists()) {
            finishWithResult(Activity.RESULT_CANCELED, "No registered face was found for this account.", false);
            return;
        }

        Bitmap storedBitmap = BitmapFactory.decodeFile(registeredFaceFile.getAbsolutePath());
        if (storedBitmap == null) {
            finishWithResult(Activity.RESULT_CANCELED, "Stored face profile is unreadable.", false);
            return;
        }

        float[] storedEmbedding = recognizer.recognizeFace(storedBitmap);
        float[] currentEmbedding = recognizer.recognizeFace(bitmap);
        float distance = euclideanDistance(storedEmbedding, currentEmbedding);

        if (distance < MATCH_THRESHOLD) {
            completed = true;
            finishWithResult(Activity.RESULT_OK, "Face verified.", true);
        } else {
            statusView.setText("Face not recognized. Hold still and try again.");
            busy = false;
        }
    }

    private Bitmap cropFace(Image mediaImage, Rect rect) {
        try {
            ByteBuffer yBuffer = mediaImage.getPlanes()[0].getBuffer();
            ByteBuffer uBuffer = mediaImage.getPlanes()[1].getBuffer();
            ByteBuffer vBuffer = mediaImage.getPlanes()[2].getBuffer();

            int ySize = yBuffer.remaining();
            int uSize = uBuffer.remaining();
            int vSize = vBuffer.remaining();

            byte[] nv21 = new byte[ySize + uSize + vSize];
            yBuffer.get(nv21, 0, ySize);
            vBuffer.get(nv21, ySize, vSize);
            uBuffer.get(nv21, ySize + vSize, uSize);

            YuvImage yuvImage =
                    new YuvImage(nv21, ImageFormat.NV21, mediaImage.getWidth(), mediaImage.getHeight(), null);
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            Rect safeRect = new Rect(
                    Math.max(0, rect.left),
                    Math.max(0, rect.top),
                    Math.min(mediaImage.getWidth(), rect.right),
                    Math.min(mediaImage.getHeight(), rect.bottom));
            yuvImage.compressToJpeg(safeRect, 100, stream);
            byte[] bytes = stream.toByteArray();
            Bitmap faceBitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
            if (faceBitmap == null) {
                return null;
            }
            return Bitmap.createScaledBitmap(faceBitmap, 112, 112, false);
        } catch (IllegalArgumentException exception) {
            return null;
        }
    }

    private float euclideanDistance(float[] embedding1, float[] embedding2) {
        float sum = 0f;
        for (int index = 0; index < embedding1.length; index++) {
            float diff = embedding1[index] - embedding2[index];
            sum += diff * diff;
        }
        return (float) Math.sqrt(sum);
    }

    private void finishWithResult(int resultCode, String message, boolean faceRegistered) {
        if (completed && resultCode != Activity.RESULT_OK) {
            return;
        }
        Intent intent = new Intent();
        intent.putExtra(EXTRA_MESSAGE, message);
        intent.putExtra(EXTRA_FACE_REGISTERED, faceRegistered);
        setResult(resultCode, intent);
        if (resultCode != Activity.RESULT_OK && !message.isEmpty()) {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        }
        finish();
    }
}
