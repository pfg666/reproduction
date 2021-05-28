import java.io.*;
import javax.net.ssl.*;

import java.security.GeneralSecurityException;
import java.security.KeyStore;

/*
 * This example shows how to set up a key manager to do client
 * authentication if required by server.
 *
 * This program assumes that the client is not inside a firewall.
 * The application can be modified to connect to a server outside
 * the firewall by following SSLSocketClientWithTunneling.java.
 */
public class SSLSocketClientWithClientAuth {
	
	static SSLContext getSSLContext(String keystore, String password) throws GeneralSecurityException, IOException {
		KeyStore ks = KeyStore.getInstance("JKS");
		KeyStore ts = KeyStore.getInstance("JKS");

		try (FileInputStream fis = new FileInputStream(keystore)) {
			ks.load(fis, password.toCharArray());
		}

		try (FileInputStream fis = new FileInputStream(keystore)) {
			ts.load(fis, password.toCharArray());
		}

		KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
		kmf.init(ks, password.toCharArray());

		TrustManagerFactory tmf = TrustManagerFactory.getInstance("SunX509");
		tmf.init(ts);

		SSLContext sslCtx = SSLContext.getInstance("TLS");
		sslCtx.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);

		return sslCtx;
	}

    public static void main(String[] args) throws Exception {
        String host = null;
        int port = -1;
        String keystore = null;
        String password = null;
        for (int i = 0; i < args.length; i++)
            System.out.println(args[i]);

        if (args.length < 4) {
            System.out.println(
                "USAGE: java SSLSocketClientWithClientAuth " +
                "host port keystore password");
            System.exit(-1);
        }

        try {
            host = args[0];
            port = Integer.parseInt(args[1]);
            keystore = args[2];
            password = args[3];
        } catch (IllegalArgumentException e) {
             System.out.println("USAGE: java SSLSocketClientWithClientAuth " +
                 "host port requestedfilepath");
             System.exit(-1);
        }

        try {

            /*
             * Set up a key manager for client authentication
             * if asked by the server.  Use the implementation's
             * default TrustStore and secureRandom routines.
             */
            SSLSocketFactory factory = null;
            SSLContext ctx = getSSLContext(keystore, password);
            try {
                factory = ctx.getSocketFactory();
            } catch (Exception e) {
                throw new IOException(e.getMessage());
            }

            SSLSocket socket = (SSLSocket)factory.createSocket(host, port);

            /*
             * send http request
             *
             * See SSLSocketClient.java for more information about why
             * there is a forced handshake here when using PrintWriters.
             */
            socket.startHandshake();
            socket.close();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
