package com.maxrave.simpmusic.viewModel

import kotlinx.coroutines.runBlocking
import org.jetbrains.compose.resources.getString
import simpmusic.composeapp.generated.resources.Res
import simpmusic.composeapp.generated.resources.home_offline_title
import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals

/** Guard against truncating zh-CN to zh and losing the Windows translation. */
class DesktopLocaleTest {
    @Test
    fun simplifiedChineseLocaleUsesPackagedTranslations() = runBlocking {
        val previous = Locale.getDefault()
        try {
            changeLanguageNative("zh-CN")
            assertEquals("zh-CN", Locale.getDefault().toLanguageTag())
            assertEquals("无法连接", getString(Res.string.home_offline_title))

            changeLanguageNative("en-US")
            assertEquals("Can't connect", getString(Res.string.home_offline_title))
        } finally {
            Locale.setDefault(previous)
        }
    }

    @Test
    fun legacyOrScriptOnlyChineseSelectionChoosesSimplifiedChinese() {
        assertEquals("zh-CN", desktopLanguageLocale("zh").toLanguageTag())
        assertEquals("zh-CN", desktopLanguageLocale("zh-Hans").toLanguageTag())
        assertEquals("zh-CN", desktopLanguageLocale("zh_CN").toLanguageTag())
        assertEquals("zh-TW", desktopLanguageLocale("zh-Hant").toLanguageTag())
        assertEquals("zh-TW", desktopLanguageLocale("zh-TW").toLanguageTag())
        assertEquals("en-US", desktopLanguageLocale("en-US").toLanguageTag())
    }
}
