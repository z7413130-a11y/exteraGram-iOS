/// Storage schema mapped independently from the public Android ExteraConfig.kt.
/// Android-only capabilities are reserved for future ports. Their defaults never activate iOS behavior.
/// Defaults which depend on an Android subsystem are represented by neutral iOS values.
public enum ExteraPreferences {
    public static let translationProvider = ExteraPreference<Int>("translationProvider", .general, 0)
    public static let disableNumberRounding = ExteraPreference<Bool>("disableNumberRounding", .general, false)
    public static let formatTimeWithSeconds = ExteraPreference<Bool>("formatTimeWithSeconds", .general, false)
    public static let relativeLastSeen = ExteraPreference<Bool>("relativeLastSeen", .general, false)
    public static let inAppVibration = ExteraPreference<Bool>("inAppVibration", .general, true)
    public static let disableNotificationDelay = ExteraPreference<Bool>("disableNotificationDelay", .general, false)
    public static let filterZalgo = ExteraPreference<Bool>("filterZalgo", .general, true)
    public static let downloadSpeedBoost = ExteraPreference<Int>("downloadSpeedBoost", .general, 0)
    public static let uploadSpeedBoost = ExteraPreference<Bool>("uploadSpeedBoost", .general, false)
    public static let hidePhoneNumber = ExteraPreference<Bool>("hidePhoneNumber", .general, false)
    public static let showIdAndDc = ExteraPreference<Int>("showIdAndDc", .general, 1)
    public static let defaultProfileTab = ExteraPreference<Int>("defaultProfileTab", .general, 0)
    public static let hideArchiveFolder = ExteraPreference<Bool>("hideArchiveFolder", .general, false)
    public static let archiveOnPull = ExteraPreference<Bool>("archiveOnPull", .general, false)
    public static let disableUnarchiveSwipe = ExteraPreference<Bool>("disableUnarchiveSwipe", .general, true)
    public static let doNotUseProxy = ExteraPreference<Int>("doNotUseProxy", .general, 0)
    public static let customSavePath = ExteraPreference<String>("customSavePath", .general, "exteraGram")
    public static let iconPack = ExteraPreference<Int>("iconPack", .appearance, 0)
    public static let editingIconPackId = ExteraPreference<String?>("editingIconPackId", .appearance, nil)
    public static let avatarCorners = ExteraPreference<Double>("avatarCorners", .appearance, 28.0)
    public static let singleCornerRadius = ExteraPreference<Bool>("singleCornerRadius", .appearance, false)
    public static let dividerStyle = ExteraPreference<Int>("dividerStyle", .appearance, 1)
    public static let forceSnow = ExteraPreference<Bool>("forceSnow", .appearance, false)
    public static let hideActionBarStatus = ExteraPreference<Bool>("hideActionBarStatus", .appearance, false)
    public static let centerTitle = ExteraPreference<Bool>("centerTitle", .appearance, false)
    public static let hideStories = ExteraPreference<Bool>("hideStories", .appearance, false)
    public static let hideFloatingButton = ExteraPreference<Bool>("hideFloatingButton", .appearance, false)
    public static let hideDialogsSearchBar = ExteraPreference<Bool>("hideDialogsSearchBar", .appearance, false)
    public static let senderMiniAvatars = ExteraPreference<Bool>("senderMiniAvatars", .appearance, true)
    public static let titleText = ExteraPreference<Int>("titleText", .appearance, 0)
    public static let tabIcons = ExteraPreference<Int>("tabIcons", .appearance, 1)
    public static let tabCounterMode = ExteraPreference<Int>("tabCounterMode", .appearance, 0)
    public static let hideAllChats = ExteraPreference<Bool>("hideAllChats", .appearance, false)
    public static let squareFab = ExteraPreference<Bool>("squareFab", .appearance, true)
    public static let sectionRadius = ExteraPreference<Double>("sectionRadius", .appearance, 20.0)
    public static let sectionsSeparatedHeaders = ExteraPreference<Bool>("sectionsSeparatedHeaders", .appearance, true)
    public static let newLoadingStyle = ExteraPreference<Bool>("newLoadingStyle", .appearance, true)
    public static let newSliderStyle = ExteraPreference<Bool>("newSliderStyle", .appearance, true)
    public static let newSwitchStyle = ExteraPreference<Bool>("newSwitchStyle", .appearance, true)
    public static let newChatHeaderStyle = ExteraPreference<Bool>("newChatHeaderStyle", .appearance, false)
    public static let newNavigationBarStyle = ExteraPreference<Bool>("newNavigationBarStyle", .appearance, false)
    public static let newFabStyle = ExteraPreference<Bool>("newFabStyle", .appearance, false)
    public static let newProfileActionsStyle = ExteraPreference<Bool>("newProfileActionsStyle", .appearance, false)
    public static let newPlayerStyle = ExteraPreference<Bool>("newPlayerStyle", .appearance, false)
    public static let playerCoverColors = ExteraPreference<Bool>("playerCoverColors", .appearance, false)
    public static let playerMiniCoverColors = ExteraPreference<Bool>("playerMiniCoverColors", .appearance, false)
    public static let lyricsOnline = ExteraPreference<Bool>("lyricsOnline", .appearance, false)
    public static let lyricsProviders = ExteraPreference<Set<String>>("lyricsProviders", .appearance, ["lrclib", "lrcmux"])
    public static let lyricsProgress = ExteraPreference<Int>("lyricsProgress", .appearance, 1)
    public static let lyricsSubtitle = ExteraPreference<Int>("lyricsSubtitle", .appearance, 1)
    public static let playerMotionCovers = ExteraPreference<Bool>("playerMotionCovers", .appearance, false)
    public static let playerSpotifyCanvas = ExteraPreference<Bool>("playerSpotifyCanvas", .appearance, false)
    public static let playerYandexCanvas = ExteraPreference<Bool>("playerYandexCanvas", .appearance, false)
    public static let playerRhythmBackground = ExteraPreference<Bool>("playerRhythmBackground", .appearance, true)
    public static let playerParticles = ExteraPreference<Bool>("playerParticles", .appearance, false)
    public static let playerSpeedPitch = ExteraPreference<Bool>("playerSpeedPitch", .appearance, false)
    public static let playerMode = ExteraPreference<Int>("playerMode", .appearance, 0)
    public static let tabletMode = ExteraPreference<Int>("tabletMode", .appearance, 0)
    public static let tabletLeftFraction = ExteraPreference<Double>("tabletLeftFraction", .appearance, 0.35)
    public static let useSystemFonts = ExteraPreference<Bool>("useSystemFonts", .appearance, true)
    public static let gooeyAvatarAnimation = ExteraPreference<Bool>("gooeyAvatarAnimation", .appearance, true)
    public static let customThemes = ExteraPreference<Bool>("customThemes", .appearance, true)
    public static let predictiveBackIntensity = ExteraPreference<Double>("predictiveBackIntensity", .appearance, 1.0)
    public static let transitionAnimation = ExteraPreference<Int>("transitionAnimation", .appearance, 2)
    public static let glassOutlineStyle = ExteraPreference<Int>("glassOutlineStyle", .appearance, 0)
    public static let glassMessageMenu = ExteraPreference<Bool>("glassMessageMenu", .appearance, true)
    public static let headerBlurStyle = ExteraPreference<Int>("headerBlurStyle", .appearance, 1)
    public static let eventType = ExteraPreference<Int>("eventType", .appearance, 0)
    public static let navigationDrawer = ExteraPreference<Bool>("navigationDrawer", .appearance, false)
    public static let immersiveDrawerAnimation = ExteraPreference<Bool>("immersiveDrawerAnimation", .appearance, false)
    public static let hideNavigationBarLabels = ExteraPreference<Bool>("hideNavigationBarLabels", .appearance, false)
    public static let showFeedTab = ExteraPreference<Bool>("showFeedTab", .appearance, false)
    public static let showFeedUnreadCounter = ExteraPreference<Bool>("showFeedUnreadCounter", .appearance, true)
    public static let stickerSize = ExteraPreference<Double>("stickerSize", .chats, 12.0)
    public static let stickerTimeMode = ExteraPreference<Int>("stickerTimeMode", .chats, 0)
    public static let replyColors = ExteraPreference<Bool>("replyColors", .chats, true)
    public static let replyEmoji = ExteraPreference<Bool>("replyEmoji", .chats, true)
    public static let replyBackground = ExteraPreference<Bool>("replyBackground", .chats, true)
    public static let stickerShape = ExteraPreference<Int>("stickerShape", .chats, 1)
    public static let unlimitedRecentStickers = ExteraPreference<Bool>("unlimitedRecentStickers", .chats, false)
    public static let hideReactionsInPrivateChats = ExteraPreference<Bool>("hideReactionsInPrivateChats", .chats, false)
    public static let hideReactionsInChannels = ExteraPreference<Bool>("hideReactionsInChannels", .chats, false)
    public static let hideReactionsInGroups = ExteraPreference<Bool>("hideReactionsInGroups", .chats, false)
    public static let doubleTapAction = ExteraPreference<Int>("doubleTapAction", .chats, 1)
    public static let doubleTapActionOutOwner = ExteraPreference<Int>("doubleTapActionOutOwner", .chats, 1)
    public static let swipeActions = ExteraPreference<String>("swipeActions", .chats, "1")
    public static let swipeActionsLoop = ExteraPreference<Bool>("swipeActionsLoop", .chats, false)
    public static let swipeActionsReversed = ExteraPreference<Bool>("swipeActionsReversed", .chats, false)
    public static let bottomButton = ExteraPreference<Int>("bottomButton", .chats, 2)
    public static let widePostsInFeed = ExteraPreference<Bool>("widePostsInFeed", .chats, true)
    public static let widePostsInChannels = ExteraPreference<Bool>("widePostsInChannels", .chats, false)
    public static let telegramAiEditor = ExteraPreference<Bool>("telegramAiEditor", .chats, true)
    public static let telegramAiSummaries = ExteraPreference<Bool>("telegramAiSummaries", .chats, true)
    public static let telegramAiInstantViewSummaries = ExteraPreference<Bool>("telegramAiInstantViewSummaries", .chats, true)
    public static let quickAdminShortcuts = ExteraPreference<Bool>("quickAdminShortcuts", .chats, true)
    public static let quickTransitionForChannels = ExteraPreference<Bool>("quickTransitionForChannels", .chats, true)
    public static let quickTransitionForTopics = ExteraPreference<Bool>("quickTransitionForTopics", .chats, true)
    public static let disableGreetingSticker = ExteraPreference<Bool>("disableGreetingSticker", .chats, false)
    public static let autoRunWidgets = ExteraPreference<Bool>("autoRunWidgets", .chats, false)
    public static let hideKeyboardOnScroll = ExteraPreference<Bool>("hideKeyboardOnScroll", .chats, true)
    public static let addCommaAfterMention = ExteraPreference<Bool>("addCommaAfterMention", .chats, true)
    public static let inlineResults = ExteraPreference<Bool>("inlineResults", .chats, true)
    public static let inlineMathResult = ExteraPreference<Bool>("inlineMathResult", .chats, true)
    public static let inlineCurrencyRates = ExteraPreference<Bool>("inlineCurrencyRates", .chats, true)
    public static let inlineUnitConversion = ExteraPreference<Bool>("inlineUnitConversion", .chats, true)
    public static let inlineTimeZones = ExteraPreference<Bool>("inlineTimeZones", .chats, false)
    public static let inlineTargetCurrency = ExteraPreference<String>("inlineTargetCurrency", .chats, "")
    public static let inlineAngleUnit = ExteraPreference<Int>("inlineAngleUnit", .chats, 0)
    public static let inlineMeasureSystem = ExteraPreference<Int>("inlineMeasureSystem", .chats, 0)
    public static let inlineDigitGrouping = ExteraPreference<Bool>("inlineDigitGrouping", .chats, true)
    public static let disableMarkdown = ExteraPreference<Bool>("disableMarkdown", .chats, false)
    public static let hideSendAsPeer = ExteraPreference<Bool>("hideSendAsPeer", .chats, false)
    public static let removeMessageTail = ExteraPreference<Bool>("removeMessageTail", .chats, true)
    public static let replaceEditedWithIcon = ExteraPreference<Bool>("replaceEditedWithIcon", .chats, true)
    public static let showOnlineStatus = ExteraPreference<Bool>("showOnlineStatus", .chats, false)
    public static let showForwardsCount = ExteraPreference<Bool>("showForwardsCount", .chats, false)
    public static let hideShareButton = ExteraPreference<Bool>("hideShareButton", .chats, false)
    public static let showResultsBeforeVoting = ExteraPreference<Bool>("showResultsBeforeVoting", .chats, false)
    public static let showCopyPhotoButton = ExteraPreference<Bool>("showCopyPhotoButton", .chats, true)
    public static let showSaveMessageButton = ExteraPreference<Bool>("showSaveMessageButton", .chats, false)
    public static let showRepeatMessageButton = ExteraPreference<Bool>("showRepeatMessageButton", .chats, false)
    public static let showClearButton = ExteraPreference<Bool>("showClearButton", .chats, true)
    public static let showHistoryButton = ExteraPreference<Bool>("showHistoryButton", .chats, false)
    public static let showReportButton = ExteraPreference<Bool>("showReportButton", .chats, true)
    public static let showGenerateButton = ExteraPreference<Bool>("showGenerateButton", .chats, true)
    public static let showDetailsButton = ExteraPreference<Bool>("showDetailsButton", .chats, false)
    public static let groupMessageMenu = ExteraPreference<Bool>("groupMessageMenu", .chats, true)
    public static let recognitionLanguage = ExteraPreference<String>("recognitionLanguage", .chats, "none")
    public static let postprocessingWithAi = ExteraPreference<Bool>("postprocessingWithAi", .chats, false)
    public static let cameraType = ExteraPreference<Int>("cameraType", .chats, 0)
    public static let extendedFramesPerSecond = ExteraPreference<Bool>("extendedFramesPerSecond", .chats, false)
    public static let cameraStabilization = ExteraPreference<Bool>("cameraStabilization", .chats, false)
    public static let cameraMirrorMode = ExteraPreference<Bool>("cameraMirrorMode", .chats, true)
    public static let videoMessagesCamera = ExteraPreference<Int>("videoMessagesCamera", .chats, 0)
    public static let rememberLastUsedCamera = ExteraPreference<Bool>("rememberLastUsedCamera", .chats, false)
    public static let startWithWideAngleCamera = ExteraPreference<Bool>("startWithWideAngleCamera", .chats, false)
    public static let zoomSlider = ExteraPreference<Bool>("zoomSlider", .chats, true)
    public static let staticZoom = ExteraPreference<Bool>("staticZoom", .chats, false)
    public static let alwaysSendInHD = ExteraPreference<Bool>("alwaysSendInHD", .chats, true)
    public static let hideCameraTile = ExteraPreference<Bool>("hideCameraTile", .chats, false)
    public static let doubleTapSeekDuration = ExteraPreference<Int>("doubleTapSeekDuration", .chats, 1)
    public static let preferOriginalQuality = ExteraPreference<Bool>("preferOriginalQuality", .chats, false)
    public static let swipeToPip = ExteraPreference<Bool>("swipeToPip", .chats, false)
    public static let unmuteWithVolumeButtons = ExteraPreference<Bool>("unmuteWithVolumeButtons", .chats, false)
    public static let pauseOnMinimizeVideo = ExteraPreference<Bool>("pauseOnMinimizeVideo", .chats, true)
    public static let pauseOnMinimizeVoice = ExteraPreference<Bool>("pauseOnMinimizeVoice", .chats, false)
    public static let pauseOnMinimizeRound = ExteraPreference<Bool>("pauseOnMinimizeRound", .chats, false)
    public static let messageExportWatermark = ExteraPreference<Bool>("messageExportWatermark", .chats, true)
    public static let messageExportSource = ExteraPreference<Bool>("messageExportSource", .chats, true)
    public static let messageExportAuthors = ExteraPreference<Bool>("messageExportAuthors", .chats, false)
    public static let messageExportTime = ExteraPreference<Bool>("messageExportTime", .chats, true)
    public static let useGoogleCrashlytics = ExteraPreference<Bool>("useGoogleCrashlytics", .other, false)
    public static let useGoogleAnalytics = ExteraPreference<Bool>("useGoogleAnalytics", .other, false)
    public static let enableAdBlock = ExteraPreference<Bool>("enableAdBlock", .other, true)
    public static let exportTypes = ExteraPreference<Int>("exportTypes", .other, 0)
    public static let exportFullChats = ExteraPreference<Int>("exportFullChats", .other, 0)
    public static let exportMediaTypes = ExteraPreference<Int>("exportMediaTypes", .other, 0)
    public static let exportSizeLimit = ExteraPreference<Int64>("exportSizeLimit", .other, 8 * 1024 * 1024)
    public static let exportFormat = ExteraPreference<Int>("exportFormat", .other, 0)
    public static let exportFolder = ExteraPreference<String>("exportFolder", .other, "")
    public static let updateScheduleTimestamp = ExteraPreference<Int64>("updateScheduleTimestamp", .other, 0)
    public static let sdkUpdateScheduleTimestamp = ExteraPreference<Int64>("sdkUpdateScheduleTimestamp", .plugins, 0)
    public static let targetLang = ExteraPreference<String>("targetLang", .chats, "")
    public static let flashWarmth = ExteraPreference<Double>("flashWarmth", .other, 0.5)
    public static let flashIntensity = ExteraPreference<Double>("flashIntensity", .other, 1)
    public static let pluginsDevMode = ExteraPreference<Bool>("pluginsDevMode", .plugins, false)
    public static let pluginsSafeMode = ExteraPreference<Bool>("pluginsSafeMode", .plugins, false)
    public static let pluginsCompactView = ExteraPreference<Bool>("pluginsCompactView", .plugins, false)
    public static let pluginsPySdkAutoUpdate = ExteraPreference<Bool>("pluginsPySdkAutoUpdate", .plugins, false)
    public static let pluginsPySdkBetaVersions = ExteraPreference<Bool>("pluginsPySdkBetaVersions", .plugins, false)
    public static let pluginsDisableArtOpts = ExteraPreference<Bool>("pluginsDisableArtOpts", .plugins, false)
    public static let pluginsUnknownSources = ExteraPreference<Bool>("pluginsUnknownSources", .plugins, false)
    public static let pluginsStaticAnalysis = ExteraPreference<Bool>("pluginsStaticAnalysis", .plugins, true)
    public static let pinnedPlugins = ExteraPreference<Set<String>>("pinnedPlugins", .plugins, [])
    public static let useSystemIconShape = ExteraPreference<Bool>("useSystemIconShape", .appearance, true)

    /// iOS-only opt-in for the send-menu command.
    public static let translateDrafts = ExteraPreference<Bool>("ios.translateDrafts", .chats, false)

    public static let androidDefinitions: [ExteraSettingDefinition] = [
        translationProvider.definition,
        disableNumberRounding.definition,
        formatTimeWithSeconds.definition,
        relativeLastSeen.definition,
        inAppVibration.definition,
        disableNotificationDelay.definition,
        filterZalgo.definition,
        downloadSpeedBoost.definition,
        uploadSpeedBoost.definition,
        hidePhoneNumber.definition,
        showIdAndDc.definition,
        defaultProfileTab.definition,
        hideArchiveFolder.definition,
        archiveOnPull.definition,
        disableUnarchiveSwipe.definition,
        doNotUseProxy.definition,
        customSavePath.definition,
        iconPack.definition,
        editingIconPackId.definition,
        avatarCorners.definition,
        singleCornerRadius.definition,
        dividerStyle.definition,
        forceSnow.definition,
        hideActionBarStatus.definition,
        centerTitle.definition,
        hideStories.definition,
        hideFloatingButton.definition,
        hideDialogsSearchBar.definition,
        senderMiniAvatars.definition,
        titleText.definition,
        tabIcons.definition,
        tabCounterMode.definition,
        hideAllChats.definition,
        squareFab.definition,
        sectionRadius.definition,
        sectionsSeparatedHeaders.definition,
        newLoadingStyle.definition,
        newSliderStyle.definition,
        newSwitchStyle.definition,
        newChatHeaderStyle.definition,
        newNavigationBarStyle.definition,
        newFabStyle.definition,
        newProfileActionsStyle.definition,
        newPlayerStyle.definition,
        playerCoverColors.definition,
        playerMiniCoverColors.definition,
        lyricsOnline.definition,
        lyricsProviders.definition,
        lyricsProgress.definition,
        lyricsSubtitle.definition,
        playerMotionCovers.definition,
        playerSpotifyCanvas.definition,
        playerYandexCanvas.definition,
        playerRhythmBackground.definition,
        playerParticles.definition,
        playerSpeedPitch.definition,
        playerMode.definition,
        tabletMode.definition,
        tabletLeftFraction.definition,
        useSystemFonts.definition,
        gooeyAvatarAnimation.definition,
        customThemes.definition,
        predictiveBackIntensity.definition,
        transitionAnimation.definition,
        glassOutlineStyle.definition,
        glassMessageMenu.definition,
        headerBlurStyle.definition,
        eventType.definition,
        navigationDrawer.definition,
        immersiveDrawerAnimation.definition,
        hideNavigationBarLabels.definition,
        showFeedTab.definition,
        showFeedUnreadCounter.definition,
        stickerSize.definition,
        stickerTimeMode.definition,
        replyColors.definition,
        replyEmoji.definition,
        replyBackground.definition,
        stickerShape.definition,
        unlimitedRecentStickers.definition,
        hideReactionsInPrivateChats.definition,
        hideReactionsInChannels.definition,
        hideReactionsInGroups.definition,
        doubleTapAction.definition,
        doubleTapActionOutOwner.definition,
        swipeActions.definition,
        swipeActionsLoop.definition,
        swipeActionsReversed.definition,
        bottomButton.definition,
        widePostsInFeed.definition,
        widePostsInChannels.definition,
        telegramAiEditor.definition,
        telegramAiSummaries.definition,
        telegramAiInstantViewSummaries.definition,
        quickAdminShortcuts.definition,
        quickTransitionForChannels.definition,
        quickTransitionForTopics.definition,
        disableGreetingSticker.definition,
        autoRunWidgets.definition,
        hideKeyboardOnScroll.definition,
        addCommaAfterMention.definition,
        inlineResults.definition,
        inlineMathResult.definition,
        inlineCurrencyRates.definition,
        inlineUnitConversion.definition,
        inlineTimeZones.definition,
        inlineTargetCurrency.definition,
        inlineAngleUnit.definition,
        inlineMeasureSystem.definition,
        inlineDigitGrouping.definition,
        disableMarkdown.definition,
        hideSendAsPeer.definition,
        removeMessageTail.definition,
        replaceEditedWithIcon.definition,
        showOnlineStatus.definition,
        showForwardsCount.definition,
        hideShareButton.definition,
        showResultsBeforeVoting.definition,
        showCopyPhotoButton.definition,
        showSaveMessageButton.definition,
        showRepeatMessageButton.definition,
        showClearButton.definition,
        showHistoryButton.definition,
        showReportButton.definition,
        showGenerateButton.definition,
        showDetailsButton.definition,
        groupMessageMenu.definition,
        recognitionLanguage.definition,
        postprocessingWithAi.definition,
        cameraType.definition,
        extendedFramesPerSecond.definition,
        cameraStabilization.definition,
        cameraMirrorMode.definition,
        videoMessagesCamera.definition,
        rememberLastUsedCamera.definition,
        startWithWideAngleCamera.definition,
        zoomSlider.definition,
        staticZoom.definition,
        alwaysSendInHD.definition,
        hideCameraTile.definition,
        doubleTapSeekDuration.definition,
        preferOriginalQuality.definition,
        swipeToPip.definition,
        unmuteWithVolumeButtons.definition,
        pauseOnMinimizeVideo.definition,
        pauseOnMinimizeVoice.definition,
        pauseOnMinimizeRound.definition,
        messageExportWatermark.definition,
        messageExportSource.definition,
        messageExportAuthors.definition,
        messageExportTime.definition,
        useGoogleCrashlytics.definition,
        useGoogleAnalytics.definition,
        enableAdBlock.definition,
        exportTypes.definition,
        exportFullChats.definition,
        exportMediaTypes.definition,
        exportSizeLimit.definition,
        exportFormat.definition,
        exportFolder.definition,
        updateScheduleTimestamp.definition,
        sdkUpdateScheduleTimestamp.definition,
        targetLang.definition,
        flashWarmth.definition,
        flashIntensity.definition,
        pluginsDevMode.definition,
        pluginsSafeMode.definition,
        pluginsCompactView.definition,
        pluginsPySdkAutoUpdate.definition,
        pluginsPySdkBetaVersions.definition,
        pluginsDisableArtOpts.definition,
        pluginsUnknownSources.definition,
        pluginsStaticAnalysis.definition,
        pinnedPlugins.definition,
        useSystemIconShape.definition,
    ]
}
