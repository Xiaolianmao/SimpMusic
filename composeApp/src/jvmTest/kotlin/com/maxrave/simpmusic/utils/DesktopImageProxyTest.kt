package com.maxrave.simpmusic.utils

import com.maxrave.domain.data.model.network.ProxyConfiguration
import com.maxrave.domain.manager.DataStoreManager
import java.net.Proxy
import java.net.URI
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class DesktopImageProxyTest {
    @Test
    fun imagesUseSavedHttpProxyAndTrackChanges() {
        var config: ProxyConfiguration? = ProxyConfiguration(
            "127.0.0.1", 7897, DataStoreManager.ProxyType.PROXY_TYPE_HTTP
        )
        val selector = desktopImageProxySelector { config }
        val initial = selector.select(URI("https://i.ytimg.com/vi/example/mqdefault.jpg")).single()
        assertEquals(Proxy.Type.HTTP, initial.type())
        assertEquals(7897, (initial.address() as java.net.InetSocketAddress).port)

        config = ProxyConfiguration("127.0.0.1", 7898, DataStoreManager.ProxyType.PROXY_TYPE_SOCKS)
        assertEquals(Proxy.Type.SOCKS, selector.select(URI("https://lh3.googleusercontent.com/a.jpg")).single().type())

        config = null
        assertEquals(Proxy.NO_PROXY, selector.select(URI("https://i.ytimg.com/vi/example/mqdefault.jpg")).single())
    }

    @Test
    fun localhostNeverLoopsBackThroughProxy() {
        val selector = desktopImageProxySelector {
            ProxyConfiguration("127.0.0.1", 7897, DataStoreManager.ProxyType.PROXY_TYPE_HTTP)
        }
        assertEquals(Proxy.NO_PROXY, selector.select(URI("http://127.0.0.1:48518/import")).single())
        assertEquals(Proxy.NO_PROXY, selector.select(URI("http://localhost:8080")).single())
    }

    @Test
    fun invalidProxySettingsDoNotBuildBrokenSocketAddresses() {
        val selector = desktopImageProxySelector {
            ProxyConfiguration("127.0.0.1", 0, DataStoreManager.ProxyType.PROXY_TYPE_HTTP)
        }
        assertEquals(Proxy.NO_PROXY, selector.select(URI("https://i.ytimg.com/")).single())
    }
}
