package com.example.libgit2;

import android.util.Base64;
import android.util.Log;
import java.io.BufferedInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;

public class GitHttpClient
{
    private static final String TAG = "GitHttpClient";

    private static final int GIT_HTTP_STATUS_CONTINUE = 100;
    private static final int GIT_HTTP_STATUS_OK = 200;
    private static final int GIT_HTTP_MOVED_PERMANENTLY = 301;
    private static final int GIT_HTTP_FOUND = 302;
    private static final int GIT_HTTP_SEE_OTHER = 303;
    private static final int GIT_HTTP_TEMPORARY_REDIRECT = 307;
    private static final int GIT_HTTP_PERMANENT_REDIRECT = 308;
    private static final int GIT_HTTP_STATUS_UNAUTHORIZED = 401;
    private static final int GIT_HTTP_STATUS_PROXY_AUTHENTICATION_REQUIRED = 407;

    private String requestMethod = "GET";
    private GitUrl url;
    private HttpURLConnection connection;
    InputStream readStream;
    private int responseCode;
    private byte[] readBuffer;
    private boolean isEof;

    static GitHttpClient make() 
    {
        Log.v(TAG, "Creating http client");
        return new GitHttpClient();
    }

    public void setRequestMethod(String type)
    {
        Log.v(TAG, "Set request type " + type);
        requestMethod = type;
    }

    public void setRequestUrl(GitUrl url)
    {
        Log.v(TAG, "Set request url " + url);
        this.url = url;
    }

    public int startRequest()
    {
        Log.v(TAG, "Start request");
        try {
            URI uri = new java.net.URI(url.scheme, null, url.host, Integer.parseInt(url.port), url.path, url.query, null);
            Log.v(TAG, "Connecting to " + uri);
            connection = (HttpURLConnection)uri.toURL().openConnection();
            connection.setRequestMethod(requestMethod);
            readStream = null;
            isEof = false;
            if ("POST".equals(requestMethod))
                connection.setDoOutput(true);
        }
        catch (Exception e) 
        {
            gitErrorSet(0, e.toString());
            return -1;
        }
        return 0;
    }

    public void setCredentials(String username, String password)
    {
        Log.v(TAG, "Credentials sent");
        connection.setRequestProperty("Authorization", 
            "Basic " + Base64.encodeToString((username + ":" + password).getBytes(StandardCharsets.UTF_8), Base64.DEFAULT));
    }

    public void setRequestProperty(String property, String value)
    {
        Log.v(TAG, "Request header " + property + " : " + value);
        connection.setRequestProperty(property, value); 
    }

    public void setChunked()
    {
        Log.v(TAG, "Chunked");
        connection.setChunkedStreamingMode(0); 
    }

    public void setCustomRequestHeader(String header)
    {
        Log.v(TAG, "Custom request header " + header);
        // TODO: Implement this
    }

    public int startReadResponse()
    {
        try {
            responseCode = connection.getResponseCode();
            Log.v(TAG, "Response code " + responseCode);
        }
        catch (Exception e)
        {
            gitErrorSet(0, e.toString());
            return -1;
        }
        return 0;
    }

    public String getHeaderFieldKey(int n)
    {
        String key = connection.getHeaderFieldKey(n);
        if (key != null)
            Log.v(TAG, "Reading header " + key + " : " + connection.getHeaderField(n));
        return key;
    }

    public String getHeaderField(int n)
    {
        return connection.getHeaderField(n);
    }

    public int getResponseCode()
    {
        return responseCode;
    }

    public void close()
    {
        Log.v(TAG, "Closing http client");
    }

    // Returns the number of bytes read (you need to make a separate call to
    // get the actual buffer contents)
    public int readBody(int maxSize)
    {
        try {
            if (isEof)
                return 0;
            if (readStream == null)
                readStream = new BufferedInputStream(connection.getInputStream());
            InputStream in = readStream;
            if (readBuffer == null)
                readBuffer = new byte[Math.max(maxSize, 4096)];
            int numBytesRead = in.read(readBuffer, 0, maxSize);
            if (numBytesRead == 0)
            {
                isEof = true;
                readStream.close();
                readStream = null;
            }
            Log.v(TAG, "Read " + numBytesRead + " bytes");
            // Peek ahead to see if we're EOF
            // if (!in.markSupported())
            //     throw new IOException("Expecting mark to be supported");
            // in.mark(1);
            // if (in.read() < 0)
            //     isEof = true;
            // in.reset();
            return numBytesRead;
        }
        catch (IOException e)
        {
            gitErrorSet(0, e.toString());
            return -1;
        }
    }

    // Call this after readBody()
    public byte[] getReadBuffer()
    {
        return readBuffer;
    }

    // Call this after readBody()
    public boolean isEof()
    {
        Log.v(TAG, "EOF " + (isEof ? "true" : "false"));
        return isEof;
    }

    public void skipBody()
    {
        Log.v(TAG, "skipBody");
        if (isEof) return;
        try {
            connection.getInputStream().close();
            isEof = true;
        }
        catch (IOException e)
        {
            // Swallow the error
        }
    }

    public int writeString(String str)
    {
        return writeBytes(str.getBytes(StandardCharsets.UTF_8));
    }

    public int writeBytes(byte[] data)
    {
        try {
            Log.v(TAG, "Sending " + data.length + " bytes");
            // Log.v(TAG, "Sending: " + new String(data, StandardCharsets.UTF_8));
            connection.getOutputStream().write(data);
        }
        catch (IOException e)
        {
            gitErrorSet(0, e.toString());
            return -1;
        }
        return 0;
    }

    public static GitUrl makeUrl(String scheme, String host, String port,
                                 String path, String query, String username,
                                 String password) {
        GitUrl url = new GitUrl();
        url.scheme = scheme;
        url.host = host;
        url.port = port;
        url.path = path;
        url.query = query;
        url.username = username;
        url.password = password;
        return url;
    }

    public static void tempDebugJvmLog(String msg) {
            Log.v(TAG, msg);
    }

    public static native void gitErrorSet(int klass, String msg);
}