package com.example.vcapp;

import androidx.multidex.MultiDex;
import io.flutter.embedding.android.FlutterActivity;
import android.content.Context;

public class MainActivity extends FlutterActivity {
    @Override
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);
        MultiDex.install(this);
    }
}