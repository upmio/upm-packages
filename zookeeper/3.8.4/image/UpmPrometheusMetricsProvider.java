package org.apache.zookeeper.metrics.prometheus;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.zookeeper.metrics.MetricsContext;
import org.apache.zookeeper.metrics.MetricsProviderLifeCycleException;

/**
 * ZooKeeper 3.8.4 Prometheus provider with the three UPM metrics that are not
 * exposed by the stock provider.  The values are read from the local four
 * letter command interface, so this class does not depend on ZooKeeper's
 * private server implementation classes and remains safe across patch levels.
 */
public final class UpmPrometheusMetricsProvider extends PrometheusMetricsProvider {
    private static final Pattern ZXID = Pattern.compile("(?m)^Zxid:\\s*0x([0-9a-fA-F]+)\\s*$");
    private static final Pattern MODE = Pattern.compile("(?m)^Mode:\\s*(\\S+)\\s*$");
    private static final int DEFAULT_CLIENT_PORT = 2181;
    private int clientPort = DEFAULT_CLIENT_PORT;

    @Override
    public void configure(Properties properties) throws MetricsProviderLifeCycleException {
        super.configure(properties);
        String configuredPort = properties.getProperty("zkClientPort");
        if (configuredPort != null && !configuredPort.isBlank()) {
            try {
                clientPort = Integer.parseInt(configuredPort);
            } catch (NumberFormatException ignored) {
                clientPort = DEFAULT_CLIENT_PORT;
            }
        }
    }

    @Override
    public void start() throws MetricsProviderLifeCycleException {
        super.start();
        MetricsContext context = super.getRootContext();
        context.registerGauge("zookeeper_upm_last_zxid", this::lastZxid);
        context.registerGauge("zookeeper_upm_is_leader", this::isLeader);
        context.registerGauge("zookeeper_upm_leader_serves", this::leaderServes);
    }

    private Number lastZxid() {
        Matcher matcher = ZXID.matcher(stat());
        if (!matcher.find()) {
            return -1L;
        }
        try {
            return Long.parseUnsignedLong(matcher.group(1), 16);
        } catch (NumberFormatException ignored) {
            return -1L;
        }
    }

    private Number isLeader() {
        return "leader".equalsIgnoreCase(mode()) ? 1L : 0L;
    }

    private Number leaderServes() {
        // This setting controls whether a quorum leader accepts client traffic;
        // ZooKeeper defaults it to "yes" when it is not explicitly configured.
        return "no".equalsIgnoreCase(System.getProperty("zookeeper.leaderServes", "yes")) ? 0L : 1L;
    }

    private String mode() {
        Matcher matcher = MODE.matcher(stat());
        return matcher.find() ? matcher.group(1) : "";
    }

    private String stat() {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", clientPort), 250);
            socket.setSoTimeout(500);
            OutputStream output = socket.getOutputStream();
            output.write("stat".getBytes(StandardCharsets.US_ASCII));
            output.flush();
            InputStream input = socket.getInputStream();
            ByteArrayOutputStream response = new ByteArrayOutputStream();
            byte[] buffer = new byte[512];
            int read;
            while ((read = input.read(buffer)) >= 0) {
                response.write(buffer, 0, read);
            }
            return response.toString(StandardCharsets.UTF_8);
        } catch (IOException ignored) {
            return "";
        }
    }
}
