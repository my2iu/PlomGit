package com.example.libgit2;

public class GitUrl {
    String scheme;
    String host;
    String port;
    String path;
    String query;
    String username;
    String password;

    public String toString()
    {
        return "url(" + scheme + "," + host + "," + port + "," + path + "," + query + "," + username + "," + password + ")";
    }
}