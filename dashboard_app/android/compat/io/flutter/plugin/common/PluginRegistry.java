package io.flutter.plugin.common;

import android.app.Activity;
import android.content.Context;

public interface PluginRegistry {
    interface Registrar {
        Activity activity();
        Context context();
        BinaryMessenger messenger();
        Registrar addRequestPermissionsResultListener(RequestPermissionsResultListener listener);
    }
    interface RequestPermissionsResultListener {
        boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults);
    }
}
