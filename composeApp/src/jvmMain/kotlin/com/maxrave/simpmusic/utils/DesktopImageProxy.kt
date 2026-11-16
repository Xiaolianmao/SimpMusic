package com.maxrave.simpmusic.utils

import com.maxrave.domain.data.model.network.ProxyConfiguration
import com.maxrave.domain.manager.DataStoreManager
import okhttp3.OkHttpClient
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.ProxySelector
import java.net.SocketAddress
import java.net.URI

/**
 * Coil uses its own OkHttp client, separate from the YouTube/Ktor client.
 * Resolve the saved proxy for each network connection so changing settings
 * does not leave thumbnails silently connecting directly.
 */
internal fun desktopImageProxySelector(readProxy: () -> ProxyConfiguration?): ProxySelector =
    object : ProxySelector() {
        override fun select(uri: URI): List<Proxy> {
            // A loopback service must not be routed back into an external proxy.
            if (uri.scheme !in listOf("http", "https") ||
                uri.host == "localhost" || uri.host == "127.0.0.1" || uri.host == "::1"
            ) return listOf(Proxy.NO_PROXY)

            val selected = runCatching { readProxy() }.getOrNull()
                ?: return listOf(Proxy.NO_PROXY)
            val host = selected.host.trim().removePrefix("http://").removePrefix("https://").trimEnd('/')
            if (host.isEmpty() || '/' in host || selected.port !in 1..65535) return listOf(Proxy.NO_PROXY)
            val type = when (selected.type) {
                DataStoreManager.ProxyType.PROXY_TYPE_HTTP -> Proxy.Type.HTTP
                DataStoreManager.ProxyType.PROXY_TYPE_SOCKS -> Proxy.Type.SOCKS
            }
            return listOf(Proxy(type, InetSocketAddress.createUnresolved(host, selected.port)))
        }

        override fun connectFailed(uri: URI?, sa: SocketAddress?, ioe: IOException?) {
            // Never include the URL (which can carry signed image tokens) in logs.
        }
    }

internal fun desktopImageHttpClient(manager: DataStoreManager): OkHttpClient =
    OkHttpClient.Builder()
        .proxySelector(desktopImageProxySelector { manager.getJVMProxy() })
        .build()
