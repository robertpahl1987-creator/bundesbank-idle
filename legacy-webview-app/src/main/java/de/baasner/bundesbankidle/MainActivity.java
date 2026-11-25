package de.baasner.bundesbankidle;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.core.content.FileProvider;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class MainActivity extends Activity {
    private static final String RELEASES =
            "https://api.github.com/repos/robertpahl1987-creator/bundesbank-idle/releases/latest";
    private static final int REQ_INSTALL = 42;

    private WebView web;
    private String pendingUrl;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.parseColor("#0b5d57"));
        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#f2efe6"));
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);   // Spielstand (localStorage)
        s.setDatabaseEnabled(true);
        s.setTextZoom(100);
        web.setWebViewClient(new WebViewClient());
        web.addJavascriptInterface(new Bridge(), "Android");
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
        checkUpdate(false);
    }

    /** Schnittstelle für das Spiel (Bank → App & Updates) */
    public class Bridge {
        @JavascriptInterface
        public String version() { return versionName(); }

        @JavascriptInterface
        public void checkUpdate() { runOnUiThread(() -> MainActivity.this.checkUpdate(true)); }
    }

    private int versionCode() {
        try {
            PackageInfo pi = getPackageManager().getPackageInfo(getPackageName(), 0);
            return pi.versionCode;
        } catch (Exception e) { return 0; }
    }

    private String versionName() {
        try {
            return getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
        } catch (Exception e) { return "?"; }
    }

    private void toast(String t) { Toast.makeText(this, t, Toast.LENGTH_LONG).show(); }

    private static String read(InputStream in) throws IOException {
        BufferedReader r = new BufferedReader(new InputStreamReader(in, "UTF-8"));
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = r.readLine()) != null) sb.append(line);
        r.close();
        return sb.toString();
    }

    /** Fragt bei GitHub nach der neuesten Version */
    private void checkUpdate(final boolean manual) {
        new Thread(() -> {
            try {
                HttpURLConnection c = (HttpURLConnection) new URL(RELEASES).openConnection();
                c.setRequestProperty("Accept", "application/vnd.github+json");
                c.setConnectTimeout(8000);
                c.setReadTimeout(8000);
                if (c.getResponseCode() != 200) throw new IOException("HTTP " + c.getResponseCode());
                JSONObject j = new JSONObject(read(c.getInputStream()));
                final String tag = j.getString("tag_name");
                String[] parts = tag.replace("v", "").split("\\.");
                final int code = 100 + Integer.parseInt(parts[parts.length - 1]);
                JSONArray assets = j.getJSONArray("assets");
                String url = null;
                for (int i = 0; i < assets.length(); i++) {
                    JSONObject a = assets.getJSONObject(i);
                    if (a.getString("name").endsWith(".apk")) url = a.getString("browser_download_url");
                }
                final String apk = url;
                runOnUiThread(() -> {
                    if (apk != null && code > versionCode()) askUpdate(tag, apk);
                    else if (manual) toast("Du hast die neueste Version (" + versionName() + ")");
                });
            } catch (Exception e) {
                if (manual) runOnUiThread(() -> toast("Update-Prüfung fehlgeschlagen. Bist du online?"));
            }
        }).start();
    }

    private void askUpdate(String tag, String url) {
        if (isFinishing()) return;
        new AlertDialog.Builder(this)
                .setTitle("Update verfügbar")
                .setMessage("Version " + tag + " ist da. Dein Spielstand bleibt erhalten.\nJetzt herunterladen und installieren?")
                .setPositiveButton("Installieren", (d, w) -> download(url))
                .setNegativeButton("Später", null)
                .show();
    }

    private void download(final String url) {
        if (Build.VERSION.SDK_INT >= 26 && !getPackageManager().canRequestPackageInstalls()) {
            pendingUrl = url;
            toast("Bitte erlaube einmalig die Installation von Updates für Bundesbank Idle.");
            startActivityForResult(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:" + getPackageName())), REQ_INSTALL);
            return;
        }
        web.evaluateJavascript("try{window.bbSave&&bbSave()}catch(e){}", null);
        final ProgressDialog pd = new ProgressDialog(this);
        pd.setMessage("Update wird geladen …");
        pd.setCancelable(false);
        pd.show();
        new Thread(() -> {
            try {
                File f = new File(getCacheDir(), "update.apk");
                HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
                c.setInstanceFollowRedirects(true);
                c.setConnectTimeout(15000);
                c.setReadTimeout(30000);
                InputStream in = c.getInputStream();
                OutputStream out = new FileOutputStream(f);
                byte[] buf = new byte[16384];
                int n;
                while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
                out.close();
                in.close();
                runOnUiThread(() -> { pd.dismiss(); install(f); });
            } catch (Exception e) {
                runOnUiThread(() -> { pd.dismiss(); toast("Download fehlgeschlagen"); });
            }
        }).start();
    }

    private void install(File f) {
        Uri uri = FileProvider.getUriForFile(this, getPackageName() + ".files", f);
        Intent i = new Intent(Intent.ACTION_VIEW);
        i.setDataAndType(uri, "application/vnd.android.package-archive");
        i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(i);
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        super.onActivityResult(req, res, data);
        if (req == REQ_INSTALL && pendingUrl != null && Build.VERSION.SDK_INT >= 26
                && getPackageManager().canRequestPackageInstalls()) {
            String u = pendingUrl;
            pendingUrl = null;
            download(u);
        }
    }

    @Override protected void onPause() { web.onPause(); super.onPause(); }
    @Override protected void onResume() { super.onResume(); web.onResume(); }

    @Override
    public void onBackPressed() {
        if (web.canGoBack()) web.goBack(); else super.onBackPressed();
    }
}
